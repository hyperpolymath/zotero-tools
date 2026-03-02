


function make(label, features, members, param) {
  return {
    label: label,
    features: features,
    members: members,
    centerOfGravity: undefined,
    boundaries: "vague"
  };
}

function belongsToFamily(item, features, family) {
  let itemFeatures = family.features.filter(f => f.exemplars.includes(item));
  let overlapScore = itemFeatures.reduce((acc, f) => acc + f.weight, 0.0);
  return overlapScore > 0.5;
}

function findPrototype(family) {
  let scores = family.members.map(member => {
    let score = family.features.reduce((acc, f) => {
      if (f.exemplars.includes(member)) {
        return acc + f.weight;
      } else {
        return acc;
      }
    }, 0.0);
    return [
      member,
      score
    ];
  });
  let sorted = scores.sort((param, param$1) => {
    let s2 = param$1[1];
    let s1 = param[1];
    if (s1 > s2) {
      return -1;
    } else if (s1 < s2) {
      return 1;
    } else {
      return 0;
    }
  });
  let match = sorted[0];
  return match[0];
}

function merge(f1, f2) {
  return {
    label: f1.label + ` + ` + f2.label,
    features: f1.features.concat(f2.features),
    members: f1.members.concat(f2.members),
    centerOfGravity: undefined,
    boundaries: "contested"
  };
}

function resemblanceStrength(item1, item2, family) {
  let features1 = family.features.filter(f => f.exemplars.includes(item1));
  let features2 = family.features.filter(f => f.exemplars.includes(item2));
  let overlap = features1.filter(f1 => features2.some(f2 => f1.name === f2.name));
  return overlap.reduce((acc, f) => acc + f.weight, 0.0);
}

function toNetwork(family) {
  let edges = [];
  family.members.forEach(m1 => {
    family.members.forEach(m2 => {
      if (m1 === m2) {
        return;
      }
      let strength = resemblanceStrength(m1, m2, family);
      if (strength > 0.0) {
        edges.push([
          m1,
          m2,
          strength
        ]);
        return;
      }
    });
  });
  return edges;
}

export {
  make,
  belongsToFamily,
  findPrototype,
  merge,
  resemblanceStrength,
  toNetwork,
}
/* No side effect */
