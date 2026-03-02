// SpeechAct.test.res
// Tests for J.L. Austin's speech act theory implementation

open RescriptMocha

describe("SpeechAct", () => {
  let testContext = EpistemicState.Scientific

  describe("make", () => {
    it("creates an assertive speech act", () => {
      let act = SpeechAct.make(
        ~utterance="The sky is blue",
        ~force=Assertive("The sky is blue"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.utterance, "The sky is blue")
      Assert.equal(act.mood.performative, false)
    })

    it("creates a performative declaration", () => {
      let act = SpeechAct.make(
        ~utterance="I hereby declare this session open",
        ~force=Declaration("session open"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, true)
    })

    it("creates a performative commissive", () => {
      let act = SpeechAct.make(
        ~utterance="I promise to finish the report",
        ~force=Commissive("finish report"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, true)
    })

    it("creates a non-performative directive", () => {
      let act = SpeechAct.make(
        ~utterance="Please close the door",
        ~force=Directive("close door"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, false)
    })

    it("creates a non-performative expressive", () => {
      let act = SpeechAct.make(
        ~utterance="Thank you so much!",
        ~force=Expressive("gratitude"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, false)
    })
  })

  describe("isHappy", () => {
    it("returns true for felicitous speech act", () => {
      let act = SpeechAct.make(
        ~utterance="I now pronounce you married",
        ~force=Declaration("married"),
        ~context=testContext,
        (),
      )

      Assert.equal(SpeechAct.isHappy(act), true)
    })

    it("checks all felicity conditions", () => {
      let act = SpeechAct.make(
        ~utterance="Test utterance",
        ~force=Assertive("test"),
        ~context=testContext,
        (),
      )

      let f = act.mood.felicity
      Assert.equal(f.conventionalProcedure, true)
      Assert.equal(f.appropriateCircumstances, true)
      Assert.equal(f.executedCorrectly, true)
      Assert.equal(f.executedCompletely, true)
      Assert.equal(f.sincereIntentions, true)
    })
  })

  describe("getMoodDescriptor", () => {
    it("describes assertive mood", () => {
      let act = SpeechAct.make(
        ~utterance="Water boils at 100°C",
        ~force=Assertive("Water boils at 100°C"),
        ~context=testContext,
        (),
      )

      Assert.equal(
        SpeechAct.getMoodDescriptor(act),
        "Asserting: Water boils at 100°C",
      )
    })

    it("describes directive mood", () => {
      let act = SpeechAct.make(
        ~utterance="Submit the form",
        ~force=Directive("submit form"),
        ~context=testContext,
        (),
      )

      Assert.equal(
        SpeechAct.getMoodDescriptor(act),
        "Directing: submit form",
      )
    })

    it("describes commissive mood", () => {
      let act = SpeechAct.make(
        ~utterance="I will attend",
        ~force=Commissive("attend meeting"),
        ~context=testContext,
        (),
      )

      Assert.equal(
        SpeechAct.getMoodDescriptor(act),
        "Committing: attend meeting",
      )
    })

    it("describes expressive mood", () => {
      let act = SpeechAct.make(
        ~utterance="I apologize",
        ~force=Expressive("regret"),
        ~context=testContext,
        (),
      )

      Assert.equal(
        SpeechAct.getMoodDescriptor(act),
        "Expressing: regret",
      )
    })

    it("describes declaration mood", () => {
      let act = SpeechAct.make(
        ~utterance="I name this ship HMS Victory",
        ~force=Declaration("ship named"),
        ~context=testContext,
        (),
      )

      Assert.equal(
        SpeechAct.getMoodDescriptor(act),
        "Declaring: ship named",
      )
    })
  })

  describe("getEmotionalTone", () => {
    it("extracts emotional tone from expressive", () => {
      let act = SpeechAct.make(
        ~utterance="I'm so sorry",
        ~force=Expressive("sorrow"),
        ~context=testContext,
        (),
      )

      switch SpeechAct.getEmotionalTone(act) {
      | Some(tone) => Assert.equal(tone, "sorrow")
      | None => Assert.fail("Expected Some(tone)")
      }
    })

    it("returns None for non-expressive speech acts", () => {
      let act = SpeechAct.make(
        ~utterance="The cat is on the mat",
        ~force=Assertive("cat location"),
        ~context=testContext,
        (),
      )

      Assert.equal(SpeechAct.getEmotionalTone(act), None)
    })
  })

  describe("conflicts", () => {
    it("detects conflict between different assertives", () => {
      let act1 = SpeechAct.make(
        ~utterance="The value is 42",
        ~force=Assertive("value is 42"),
        ~context=testContext,
        (),
      )

      let act2 = SpeechAct.make(
        ~utterance="The value is 7",
        ~force=Assertive("value is 7"),
        ~context=testContext,
        (),
      )

      Assert.equal(SpeechAct.conflicts(act1, act2), true)
    })

    it("detects conflict between different declarations", () => {
      let act1 = SpeechAct.make(
        ~utterance="I declare victory",
        ~force=Declaration("victory"),
        ~context=testContext,
        (),
      )

      let act2 = SpeechAct.make(
        ~utterance="I declare defeat",
        ~force=Declaration("defeat"),
        ~context=testContext,
        (),
      )

      Assert.equal(SpeechAct.conflicts(act1, act2), true)
    })

    it("does not detect conflict between same assertives", () => {
      let act1 = SpeechAct.make(
        ~utterance="The sky is blue",
        ~force=Assertive("sky is blue"),
        ~context=testContext,
        (),
      )

      let act2 = SpeechAct.make(
        ~utterance="The sky is blue",
        ~force=Assertive("sky is blue"),
        ~context=testContext,
        (),
      )

      Assert.equal(SpeechAct.conflicts(act1, act2), false)
    })

    it("does not detect conflict between different force types", () => {
      let act1 = SpeechAct.make(
        ~utterance="Close the door",
        ~force=Directive("close door"),
        ~context=testContext,
        (),
      )

      let act2 = SpeechAct.make(
        ~utterance="The door is open",
        ~force=Assertive("door is open"),
        ~context=testContext,
        (),
      )

      Assert.equal(SpeechAct.conflicts(act1, act2), false)
    })
  })

  describe("performatives", () => {
    it("identifies declarations as performative", () => {
      let act = SpeechAct.make(
        ~utterance="I hereby name you",
        ~force=Declaration("naming"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, true)
    })

    it("identifies commissives as performative", () => {
      let act = SpeechAct.make(
        ~utterance="I promise to help",
        ~force=Commissive("help"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, true)
    })

    it("identifies assertives as non-performative", () => {
      let act = SpeechAct.make(
        ~utterance="Rain is water",
        ~force=Assertive("rain is water"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, false)
    })

    it("identifies directives as non-performative", () => {
      let act = SpeechAct.make(
        ~utterance="Go away",
        ~force=Directive("leave"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, false)
    })

    it("identifies expressives as non-performative", () => {
      let act = SpeechAct.make(
        ~utterance="Congratulations!",
        ~force=Expressive("joy"),
        ~context=testContext,
        (),
      )

      Assert.equal(act.mood.performative, false)
    })
  })
})
