// FamilyResemblance.test.res
// Tests for Wittgenstein's family resemblance concept

open RescriptMocha

describe("FamilyResemblance", () => {
  // Test data: "Game" example from Philosophical Investigations §66
  let gameFeatures = [
    {
      name: "competition",
      weight: 0.3,
      exemplars: ["chess", "football", "tennis"],
    },
    {
      name: "skill",
      weight: 0.3,
      exemplars: ["chess", "tennis", "poker"],
    },
    {
      name: "amusement",
      weight: 0.2,
      exemplars: ["solitaire", "ring-around-the-rosie", "peek-a-boo"],
    },
    {
      name: "luck",
      weight: 0.2,
      exemplars: ["poker", "dice", "lottery"],
    },
    {
      name: "teams",
      weight: 0.15,
      exemplars: ["football", "baseball", "volleyball"],
    },
  ]

  let gameMembers = [
    "chess",
    "football",
    "tennis",
    "poker",
    "solitaire",
    "dice",
  ]

  describe("make", () => {
    it("creates a family resemblance cluster", () => {
      let games = FamilyResemblance.make(
        ~label="Games",
        ~features=gameFeatures,
        ~members=gameMembers,
        (),
      )

      Assert.equal(games.label, "Games")
      Assert.equal(Js.Array2.length(games.members), 6)
      Assert.equal(games.boundaries, "vague")
    })

    it("initializes with no center of gravity", () => {
      let games = FamilyResemblance.make(
        ~label="Games",
        ~features=gameFeatures,
        ~members=gameMembers,
        (),
      )

      Assert.equal(games.centerOfGravity, None)
    })

    it("sets vague boundaries by default", () => {
      let cluster = FamilyResemblance.make(
        ~label="Test",
        ~features=[],
        ~members=[],
        (),
      )

      Assert.equal(cluster.boundaries, "vague")
    })
  })

  describe("belongsToFamily", () => {
    let games = FamilyResemblance.make(
      ~label="Games",
      ~features=gameFeatures,
      ~members=gameMembers,
      (),
    )

    it("accepts item with sufficient overlapping features", () => {
      // Chess has competition + skill = 0.6 > 0.5 threshold
      let belongs = FamilyResemblance.belongsToFamily(
        "chess",
        ["competition", "skill"],
        games,
      )

      Assert.equal(belongs, true)
    })

    it("accepts item at boundary threshold", () => {
      // Poker has skill + luck = 0.5 (exactly at threshold, but > 0.5)
      let belongs = FamilyResemblance.belongsToFamily(
        "poker",
        ["skill", "luck"],
        games,
      )

      Assert.equal(belongs, true)
    })
  })

  describe("findPrototype", () => {
    it("finds prototypical member with most features", () => {
      let games = FamilyResemblance.make(
        ~label="Games",
        ~features=gameFeatures,
        ~members=gameMembers,
        (),
      )

      let prototype = FamilyResemblance.findPrototype(games)

      switch prototype {
      | Some(game) =>
        // Chess or tennis likely (both have competition + skill)
        Assert.ok(game == "chess" || game == "tennis" || game == "poker")
      | None => Assert.fail("Expected a prototype")
      }
    })

    it("returns None for empty family", () => {
      let emptyFamily = FamilyResemblance.make(
        ~label="Empty",
        ~features=[],
        ~members=[],
        (),
      )

      Assert.equal(FamilyResemblance.findPrototype(emptyFamily), None)
    })

    it("returns Some for single-member family", () => {
      let singleMember = FamilyResemblance.make(
        ~label="Singular",
        ~features=[{name: "trait", weight: 1.0, exemplars: ["only"]}],
        ~members=["only"],
        (),
      )

      switch FamilyResemblance.findPrototype(singleMember) {
      | Some(member) => Assert.equal(member, "only")
      | None => Assert.fail("Expected single member as prototype")
      }
    })
  })

  describe("merge", () => {
    let indoor = FamilyResemblance.make(
      ~label="Indoor Games",
      ~features=[
        {name: "indoors", weight: 0.5, exemplars: ["chess", "poker"]},
      ],
      ~members=["chess", "poker"],
      (),
    )

    let outdoor = FamilyResemblance.make(
      ~label="Outdoor Games",
      ~features=[
        {name: "outdoors", weight: 0.5, exemplars: ["football", "tennis"]},
      ],
      ~members=["football", "tennis"],
      (),
    )

    it("combines features from both families", () => {
      let merged = FamilyResemblance.merge(indoor, outdoor)

      Assert.equal(Js.Array2.length(merged.features), 2)
    })

    it("combines members from both families", () => {
      let merged = FamilyResemblance.merge(indoor, outdoor)

      Assert.equal(Js.Array2.length(merged.members), 4)
      Assert.ok(Js.Array2.includes(merged.members, "chess"))
      Assert.ok(Js.Array2.includes(merged.members, "football"))
    })

    it("creates contested boundaries", () => {
      let merged = FamilyResemblance.merge(indoor, outdoor)

      Assert.equal(merged.boundaries, "contested")
    })

    it("creates combined label", () => {
      let merged = FamilyResemblance.merge(indoor, outdoor)

      Assert.equal(merged.label, "Indoor Games + Outdoor Games")
    })

    it("resets center of gravity", () => {
      let merged = FamilyResemblance.merge(indoor, outdoor)

      Assert.equal(merged.centerOfGravity, None)
    })
  })

  describe("resemblanceStrength", () => {
    let games = FamilyResemblance.make(
      ~label="Games",
      ~features=gameFeatures,
      ~members=gameMembers,
      (),
    )

    it("calculates high resemblance for items sharing many features", () => {
      // Chess and tennis both have competition + skill
      let strength = FamilyResemblance.resemblanceStrength("chess", "tennis", games)

      Assert.ok(strength > 0.5) // At least competition (0.3) + skill (0.3)
    })

    it("calculates low resemblance for items sharing few features", () => {
      // Chess (competition, skill) vs dice (luck) - no overlap
      let strength = FamilyResemblance.resemblanceStrength("chess", "dice", games)

      Assert.equal(strength, 0.0)
    })

    it("calculates zero resemblance for non-overlapping items", () => {
      // Solitaire (amusement) vs football (competition, teams) - no overlap
      let strength = FamilyResemblance.resemblanceStrength(
        "solitaire",
        "football",
        games,
      )

      Assert.equal(strength, 0.0)
    })

    it("is symmetric (strength(A,B) == strength(B,A))", () => {
      let strengthAB = FamilyResemblance.resemblanceStrength("chess", "poker", games)
      let strengthBA = FamilyResemblance.resemblanceStrength("poker", "chess", games)

      Assert.equal(strengthAB, strengthBA)
    })
  })

  describe("toNetwork", () => {
    let games = FamilyResemblance.make(
      ~label="Games",
      ~features=gameFeatures,
      ~members=gameMembers,
      (),
    )

    it("creates network edges between members", () => {
      let network = FamilyResemblance.toNetwork(games)

      Assert.ok(Js.Array2.length(network) > 0)
    })

    it("only includes edges with positive strength", () => {
      let network = FamilyResemblance.toNetwork(games)

      Js.Array2.forEach(network, ((_, _, strength)) => {
        Assert.ok(strength > 0.0)
      })
    })

    it("does not create self-edges", () => {
      let network = FamilyResemblance.toNetwork(games)

      Js.Array2.forEach(network, ((from, to, _)) => {
        Assert.ok(from != to)
      })
    })

    it("creates edges for items with shared features", () => {
      let network = FamilyResemblance.toNetwork(games)

      // Chess and tennis should be connected (both have competition + skill)
      let chessToTennis = Js.Array2.some(network, ((from, to, _)) =>
        (from == "chess" && to == "tennis") || (from == "tennis" && to == "chess")
      )

      Assert.equal(chessToTennis, true)
    })

    it("returns empty network for family with no overlapping features", () => {
      let isolated = FamilyResemblance.make(
        ~label="Isolated",
        ~features=[
          {name: "a", weight: 1.0, exemplars: ["item1"]},
          {name: "b", weight: 1.0, exemplars: ["item2"]},
        ],
        ~members=["item1", "item2"],
        (),
      )

      let network = FamilyResemblance.toNetwork(isolated)

      Assert.equal(Js.Array2.length(network), 0)
    })
  })

  describe("vague boundaries", () => {
    it("demonstrates Wittgenstein's point about vague concepts", () => {
      // "Is throwing a ball up and catching it a game?"
      // No definitive answer - vague boundaries!
      let throwingBall = FamilyResemblance.make(
        ~label="Ball Games",
        ~features=[
          {name: "amusement", weight: 0.2, exemplars: ["throw-and-catch"]},
        ],
        ~members=["throw-and-catch"],
        (),
      )

      Assert.equal(throwingBall.boundaries, "vague")
    })
  })
})
