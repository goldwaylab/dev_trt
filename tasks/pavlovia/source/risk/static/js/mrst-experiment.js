// get subject id
function getSub(arr) {
  x = arr.find(i => i.includes('sb=')); // go through array, grab element that includes subject code 
  return x;
}

var subj = getSub(window.location.search.split('?')).split('sb=')[1].split("&")[0];
console.log('subject:',subj);


//get participant_ID
function getParticipant_ID(arr) {
  y = arr.find(i => i.includes('participant_ID=')); // go through array, grab element that includes subject code 
  return y;
}

var participant_ID = getParticipant_ID(window.location.search.split('&')).split('participant_ID=')[1];
console.log('participant_ID:',participant_ID);



// get age

function getAge(arr) {
  z = arr.find(i => i.includes('age=')); // go through array, grab element that includes subject age 
  return z;
}

var age = getAge(window.location.search.split('&')).split('age=')[1];
console.log('age:',age);



//---------------------------------------//
// Define parameters.
//---------------------------------------//

// Define bandit parameters.
// const probs = [0.20, 0.40, 0.60, 0.80];
const probs = [0.20, 0.50, 0.80];

// Define response parameters.
const valid_responses = ['arrowleft', 'arrowright'];

// Define trial timings.
const choice_duration = 6000;
const feedback_duration = 450;
const outcome_duration = 1300;

// Define screen size parameters.
var min_width = 480;
var min_height = 295;

// Define quality assurance parameters.
//var missed_threshold = 12;
//var missed_responses = 0;
//var fast_threshold = 20;
//var fast_responses = 0;

//---------------------------------------//
// Define stimuli.
//---------------------------------------//

// Define stimuli.
// var stimuli = jsPsych.randomization.shuffle([
//   jsPsych.randomization.shuffle([
//     './static/img/animals/bird-crane-shape.svg',
//     './static/img/animals/deer-silhouette.svg',
//     './static/img/animals/gecko-reptile-shape.svg',
//     './static/img/animals/seahorse-silhouette.svg'
//   ]),
//   jsPsych.randomization.shuffle([
//     './static/img/animals/snail-shape.svg',
//     './static/img/animals/kangaroo-shape.svg',
//     './static/img/animals/frog-shape.svg',
//     './static/img/animals/parrot-shape.svg'
//   ]),
//   jsPsych.randomization.shuffle([
//     './static/img/animals/bear-black-shape.svg',
//     './static/img/animals/bird-shape.svg',
//     './static/img/animals/crocodile-shape.svg',
//     './static/img/animals/monkey.svg'
//   ]),
//   jsPsych.randomization.shuffle([
//     './static/img/animals/squirrel-shape.svg',
//     './static/img/animals/bull-silhouette.svg',
//     './static/img/animals/dolphin-mammal-animal-silhouette.svg',
//     './static/img/animals/swift-bird-shape.svg'
//   ])
// ])
var stimuli = jsPsych.randomization.shuffle([
  jsPsych.randomization.shuffle([
    './static/img/session1/group1/bird-crane-shape.svg',
    './static/img/session1/group1/deer-silhouette.svg',
    './static/img/session1/group1/seahorse-silhouette.svg'
  ]),
  jsPsych.randomization.shuffle([
    './static/img/session1/group2/fish-shape-of-dragonet.svg',
    './static/img/session1/group2/kangaroo-shape.svg',
    './static/img/session1/group2/parrot-shape.svg'
  ]),
  jsPsych.randomization.shuffle([
    './static/img/session1/group3/bear-black-shape.svg',
    './static/img/session1/group3/bird-shape.svg',
    './static/img/session1/group3/fish-batfish-shape.svg'
  ]),
  jsPsych.randomization.shuffle([
    './static/img/session1/group4/dolphin-mammal-animal-silhouette.svg',
    './static/img/session1/group4/moose-shape.svg',
    './static/img/session1/group4/swift-bird-shape.svg'
  ]),
  jsPsych.randomization.shuffle([
    './static/img/session1/group5/gazelle-running-silhouette.svg',
    './static/img/session1/group5/bird-waterfowl-shape.svg',
    './static/img/session1/group5/fish-of-triangular-shape.svg'
  ])
])
stimuli = [].concat.apply([], stimuli);
stimuli = stimuli.concat([
  './static/img/instructions.png',
  './static/img/all_animals/rabbit-shape.svg',
  './static/img/all_animals/horse-black-shape.svg',
]);

// Define colors.
var orderedArray = [0,1,2,3,4];

var order = jsPsych.randomization.repeat(orderedArray, 1);

// var order = jsPsych.randomization.sampleWithoutReplacement([
//   [0,2,1,3], [0,2,3,1], [2,0,1,3], [2,0,3,1],
//   [1,3,0,2], [1,3,2,0], [3,1,0,2], [3,1,2,0]
// ], 1)[0];
 
// [0,2,1], [2,0,1], [1,0,2], [1,2,0]], 1)[0];

console.log('order:',order);


var colors = [];
// order.forEach((i) => {
//   if (i==0) {
//     colors = colors.concat(jsPsych.randomization.shuffle(['#387da2','#993333','#b19e3c','#6e6e6e']));
//   } else if (i==1) {
//     colors = colors.concat(jsPsych.randomization.shuffle(['#245169','#732626','#8b7c2f','#5c5c5c']));
//   } else if (i==2) {
//     colors = colors.concat(jsPsych.randomization.shuffle(['#538348','#bc6d2f','#6a4173','#56391c']));
//   } else {
//     colors = colors.concat(jsPsych.randomization.shuffle(['#3e6236','#a15417','#4c2f52','#4e3419']));
//   }
// })
order.forEach((i) => {
  if (i==0) {
    colors = colors.concat(jsPsych.randomization.shuffle(['#387da2','#993333','#b19e3c']));
  } else if (i==1) {
    colors = colors.concat(jsPsych.randomization.shuffle(['#245169','#732626','#8b7c2f']));
  } else if (i==2) {
    colors = colors.concat(jsPsych.randomization.shuffle(['#538348','#bc6d2f','#6a4173']));
  } else if (i==3) {
    colors = colors.concat(jsPsych.randomization.shuffle(['#b0783f','#081363','#750606']));
  } else {
    colors = colors.concat(jsPsych.randomization.shuffle(['#3e6236','#a15417','#4c2f52']));
  }
})

console.log('colors:',colors);

//---------------------------------------//
// Define trials.
//---------------------------------------//

// Preallocate space.
var MRST = [];

// Iteratively construct trials.
var exposure = Array(16).fill(0); // NB: changed this to reflect the number of options the participants have
var trial_no = 0;

// Iterate over (pseudo) blocks.
for (let i = 0; i < 5; i++) { // NB: changed this to reflect addition of another block

  // Define bandits
  var bandits = [...Array(3).keys()].map(j => i * 3 + j); // NB: I think we have 3 bandits

  // Iterate over trials.
  for (let j = 0; j < 16; j++) { // NB: changed to 16 for 16 trials

    // Randomize bandit orders.
    bandits = jsPsych.randomization.shuffle(bandits);

    // Iterate over bandits
    bandits.forEach((k) => {

      // RNG elements
      const points = Math.random() < probs[k % 3] ? 10 : 0; // NB: changed this to reflect 3 probs

      // Define screen check.
      const screen_check = {
        timeline: [{
          type: 'screen-check',
          min_width: min_width,
          min_height: min_height
        }],
        conditional_function: function() {
          if (window.innerWidth >= min_width && window.innerHeight >= min_height) {
            return false;
          } else {
            return true;
          }
        }
      }

      // Define trial
      var trial = {
        type: 'mrst-trial',
        stimulus: stimuli[k],
        color: colors[k],
        points: points,
        randomize: true,
        valid_responses: valid_responses,
        choice_duration: choice_duration,
        feedback_duration: feedback_duration,
        outcome_duration: outcome_duration,
        data: {
          age: age,
          subject: subj,
          participantId: participant_ID,
          phase: 'experiment',
          block: Math.floor(i / 2) + 1,
          trial: trial_no + 1,
          exposure: exposure[k]+1,
          bandit: k + 1,
          probability: probs[k % 3], // NB: changed this to reflect 3 probs
        },
        on_finish: function(data) {

          // Store number of browser interactions
          data.browser_interactions = jsPsych.data.getInteractionData().filter({trial: data.trial_index}).count();

          // Evaluate missing data
          if ( data.choice == null ) {

            // Set missing data to true.
            data.missing = true;

            // Increment counter.
     //       missed_responses++;

            // Check if experiment should end.
           // if (missed_responses >= missed_threshold) {
             // low_quality = true;
              //jsPsych.endExperiment();
        //    }

          } else {

            // Set missing data to false.
            data.missing = false;

            // Evaluate rapid responses.
       //     if ( data.rt < 200 ) {
         //     fast_responses++;
           // }

            // Check if experiment should end.
          //  if (fast_responses >= fast_threshold) {
            //  low_quality = true;
              //jsPsych.endExperiment();
         //   }

          }

        }

      }

      // Define looping node.
      const trial_node = {
        timeline: [screen_check, trial],
        loop_function: function(data) {
          return data.values()[0].missing;
        }
      }

      // Append trial.
      MRST.push(trial_node);

      // Increment counters
      trial_no++;
      exposure[k]++;

    })

  }

}

//------------------------------------//
// Define transition screens.
//------------------------------------//

// Define ready screen.
var READY_01 = {
  type: 'mrst-instructions',
  pages: [
    {
      prompt: "<p>Great job! We will now begin the real game.</p><p>The game will be broken into two parts.</p>",
      audio: './static/audio/Risk_29__gj_now_begin_real_game.mp3',
     view_duration: 5000

    },
    {
      prompt: "<p>You will be able to take a break between each part of the game.</p><p>However, please give your undivided attention during the game.</p>",
      audio: './static/audio/Risk_30__able_to_take_break.mp3',
     view_duration: 9000
    },
    {
      prompt: "<p style='line-height: 1.7em;'><b>Remember</b>: To win the most points, choose the animal card if you<br>think it has a greater chance of giving you 10 points than 0 points.<br>Otherwise choose the face-up card.</p>",
      audio: './static/audio/Risk_31__remember_to_win_most_points.mp3',
     view_duration: 11000
    },
    {
      prompt: "<p>Get ready to begin <b>Block 1 of 2</b>. It will take 6-7 minutes.</p><p>Press next when you're ready to start.</p>",
      audio: './static/audio/Risk_32__get_ready_to_begin_block_1_of_2.mp3',
      view_duration: 8000
    }
  ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_finish: function(trial) {
    pass_message('starting block 1')
  }
}

var READY_02 = {
  type: 'mrst-instructions',
  pages: [
    {
      prompt: "<p>Take a break for a few moments and press any button</p><p>when you are ready to continue.</p>",
      audio: './static/audio/Risk_33__take_a_break.mp3',
     view_duration: 5000
    },
    {
      prompt: "<p>Get ready to begin <b>Block 2 of 2</b>. It will take 6-7 minutes.</p><p>Press next when you're ready to start.</p>",
      audio: './static/audio/redo_risk34b.mp3',
     view_duration: 5000
    }
  ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_finish: function(trial) {
    pass_message('starting block 2')
  }
}

var FINISHED = {
  type: 'mrst-instructions',
  pages: [
    {
      prompt: "<p>Great job! You've finished the task.</p><p> On the next screen, wait for the dialog box to appear. Then press <b>leave</b>.</p>",
      audio: './static/audio/redo_riskend.mp3',
      view_duration: 5000

    }
  ],
  show_clickable_nav: false,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_finish: function(trial) {
    pass_message('starting surveys')
  }
}