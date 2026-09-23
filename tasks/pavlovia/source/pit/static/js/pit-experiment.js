//------------------------------------//
// Define experiment parameters.
//------------------------------------//
// SOME code
console.log('5');
// Define trial structure.
practice_runsheet = [runsheets[0]]; // first runsheet is practice, needs to be first
task_runsheets = jsPsych.randomization.shuffle(runsheets.slice(1)); // shuffle remaining two
runsheets = practice_runsheet.concat(task_runsheets); // join together

// get subject id
function getSub(arr) {
  x = arr.find(i => i.includes('sb=')); // go through array, grab element that includes subject code 
  return x;
}

var subj = getSub(window.location.search.split('?')).split('sb=')[1].split("&")[0];
console.log('subject:',subj);

//console.log('subject:',subj);
 //get participant_ID
function getParticipant_ID(arr) {
  y = arr.find(i => i.includes('participant_ID=')); // go through array, grab element that includes subject code 
  return y;
}

var participant_ID = getParticipant_ID(window.location.search.split('&')).split('participant_ID=')[1];
console.log('participant_ID:',participant_ID);
console.log('participant_ID:',y);



// get age

function getAge(arr) {
  z = arr.find(i => i.includes('age=')); // go through array, grab element that includes subject age 
  return z;
}


// Define rune sets.
const rune_sets = ['elianto'/*,'bacs1','bacs2', 'elianto'*/];  
const rune_prob = [1 /*0.33,0.33,0.33*/];

// Define aesthetics.
if ( Math.random() < 1 ) {
  var instr_color_win    = 'blue';
  var scanner_color_win  = '#3366ff99';
  var outcome_color_win  = '#1a3ea7';
  var instr_color_lose   = 'red';
  var scanner_color_lose = '#f73b6a7A';
  var outcome_color_lose = '#930a25';
} else {
  var instr_color_win    = 'red';
  var scanner_color_win  =  '#f73b6a7A';
  var outcome_color_win  = '#930a25';
  var instr_color_lose   = 'blue';
  var scanner_color_lose = '#3366ff99';
  var outcome_color_lose = '#1a3ea7';
}

// Define go key.
//const key_go = 32;
const key_go = " "
// Define timings.
var browser_interactions=[]

var trial_duration = 2000;         // Duration of trial (response phase)
var feedback_duration = 2000;      // Duration of feedback (minimum)

if (subj=='test'){ 
  trial_duration = 500;         // Duration of trial (response phase)
  feedback_duration = 500;
}
  
//} else{
//const trial_duration = 2000;         // Duration of trial (response phase)
//const feedback_duration = 2000;      // Duration of feedback (minimum)
//}

// Define payment.
const completion_bonus = 0.00;
const performance_bonus = 1.50;

//------------------------------------//
// Define rune order.
//------------------------------------//
// Randomly select rune set.
const rune_set = jsPsych.randomization.sampleWithReplacement(rune_sets, 1, rune_prob)[0];

// Gather rune orders.
const runes_p = ['&#9728;', '&#9730;', '&#9733;', '&#9752;', '&#9812;', '&#9825;']; // runes for practice block
if ( rune_set == 'elianto' ) {
  var runes_a = ['u', 'l', 'a', 'g', 'p', 's', 'w', 'e', 'd', 'j']; // NB: removed 2 letters
  var runes_b = ['m', 'r', 'y', 'h', 'z', 'c', 'b', 't', 'f', 'n']; // NB: removed 2 letters
}

/*else if ( rune_set == 'bacs1' ) {
  var runes_a = ['B', 'Z', 'J', 'R', 'V', 'E', 'T', 'F', 'A', 'C', 'L', 'Q'];
  var runes_b = ['Y', 'H', 'P', 'M', 'U', 'S', 'K', 'D', 'O', 'I', 'G', 'N'];
} else if ( rune_set == 'bacs2' ) {
  var runes_a = ['J', 'W', 'X', 'Z', 'G', 'O', 'C', 'E', 'H', 'Q', 'T', 'Y'];
  var runes_b = ['M', 'B', 'K', 'V', 'R', 'P', 'L', 'S', 'U', 'A', 'F', 'N'];
}
*/

// Randomize presentation order.
if ( Math.random() < 0.5 ) { runes_a = runes_a.reverse(); }
if ( Math.random() < 0.5 ) { runes_b = runes_b.reverse(); }
var runes = ( Math.random() < 0.5 ) ? [runes_p, runes_a, runes_b] : [runes_p, runes_b, runes_a];

//------------------------------------//
// Define experiment.
//------------------------------------//
// One block of the PIT task is comprised of 10-14 exposures to 10 robots, or
// 120 total trials. 80% of trials provide correct feedback. There are 2 total
// blocks, or 240 total trials.

// Preallocate space.
var PIT = [];

// Iteratively define trials.
var n = 0;
for (let i=0; i<runsheets.length; i++) {

  for (let j=0; j<runsheets[i]['robots'].length; j++) {

    jsPsych.randomization.shuffle([0,1,2,3]).forEach(function (k) {

      // Extract trial information.
      const robot    = runsheets[i]['robots'][j][k];
      const stimulus = runsheets[i]['stimuli'][j][k];

      // Define trial metadata.
      const valence = (robot < 2) ? 'win' : 'lose';
      const action = (robot % 2 == 0) ? 'go' : 'no-go';

      // Define trial outcomes.
      const sham = (Math.random() < 0.8) ? 0 : 1;
      if (valence == 'win' && sham == 0) {
        var outcome_correct   = '+10';
        var outcome_incorrect = '0';
      } else if (valence == 'win') {
        var outcome_correct   = '0';
        var outcome_incorrect = '+10';
      } else if (valence == 'lose' && sham == 0) {
        var outcome_correct   = '0';
        var outcome_incorrect = '-10';
      } else {
        var outcome_correct   = '-10';
        var outcome_incorrect = '0';
      }

      // Define trial.
      const trial = {
        type: 'pit-trial',
        robot_rune: runes[i][stimulus],
        scanner_color: valence == 'win' ? scanner_color_win : scanner_color_lose,
        outcome_color: valence == 'win' ? outcome_color_win : outcome_color_lose,
        outcome_correct: outcome_correct,
        outcome_incorrect: outcome_incorrect,
        correct: robot % 2 == 0 ? key_go : -1,
        rune_set: rune_set,
        valid_responses: [key_go],
        trial_duration: trial_duration,
        feedback_duration: feedback_duration,
        data: {
          sub: subj,
          block: i + 1,
          trial: n + 1,
          stimulus: stimulus,
          robot: robot + 1,
          valence: valence,
          action: action,
          sham: sham
        }
      };

      // Append.
      PIT.push(trial);
      n++;

    });

  }

}


//------------------------------------//
// Define transition screens.
//------------------------------------//

// Define ready screen.

var READY_PRACTICE = {
  type: 'pit-instructions',
  pages: [
    "Great job! You've passed the comprehension check.",
    "We will now do a short practice to show you what the real game will be like. <br>",
    "Get ready to begin <b>the practice block</b>. It will take ~2 minutes.<br>Press next when you're ready to start.",
  ],
     robot_runes: [
    ''
  ],
  scanner_colors: [
    '#FFFFFF00'
],
 audio: ['./static/audio/PITa_passedcompcheck.mp3','./static/audio/PITb_shortpractice.mp3','./static/audio/PITc_getreadypracticeblcok.mp3'],
  
  view_duration: [
      3000,5000,6000
      ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_finish: function() {
    pass_message('starting block 1');
  }
};


var READY_01 = {
  type: 'pit-instructions',
  pages: [
    "Great job! You've completed the practice block. We will now move onto the real game.",
    "Get ready to begin <b>the first block</b>. It will take ~7 minutes.<br>Press next when you're ready to start.",
  ],
     robot_runes: [
    ''
  ],
  scanner_colors: [
    '#FFFFFF00'
],
audio: ['./static/audio/PITd_completedpracticeblock.mp3','./static/audio/PITe_getreadyfirstblock.mp3'],
  
  view_duration: [
      5000,6000
      ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_finish: function() {
    pass_message('starting block 1');
  }
};

var READY_02 = {
  type: 'pit-instructions',
  pages: [
    "Take a break for a few moments and press next when you are ready to continue.",
    "Get ready to begin <b>the second and last block</b>. It will take ~7 minutes.<br>Press next when you're ready to start.",
  ],
     robot_runes: [
    ''
  ],
  scanner_colors: [
    '#FFFFFF00'
],
audio: ['./static/audio/PITf_takeabreak.mp3','./static/audio/PITg_second_lastblock.mp3'],
  
  view_duration: [
      5000,8000
      ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_finish: function() {
    pass_message('starting block 2');
  }
};

// Define finish screen.
var FINISHED = {
  type: 'pit-instructions',
  pages: [
    "<p>Great job! You've finished the task.</p><p> On the next screen, wait 10 seconds for the dialog box to appear. Then press <b>leave</b>.</p>",
    
      

  ],
  
     robot_runes: [
    ''
  ],
  scanner_colors: [
    '#FFFFFF00'
],
audio:['./static/audio/PITh_finishedthetask.mp3'],
      view_duration: [5000],

  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
};

// Define feedback screen.
//var FEEDBACK = {
  //stimulus: '',
  //type: 'html-keyboard-response',
 // on_start: function(trial) {

    // Compute overall accuracy.
   // var accuracy = jsPsych.data.get().filter([{Block: 1}, {Block:2}]).select('Accuracy');
//    accuracy = accuracy.mean();

    // Compute payment.
  //  var bonus = completion_bonus + Math.ceil(performance_bonus * accuracy * 100) / 100;
    //var total = completion_bonus + performance_bonus;

    // Report accuracy to subject.
//    trial.stimulus = `You earned a bonus of $${bonus} out of $${total}.<br><br>Press any key to complete the experiment.`;

//  }
  
  
//};

  //on_finish: function(trial) {
      
      


    // Compute overall accuracy.
    //var accuracy = jsPsych.data.get().filter([{Block: 1}, {Block:2}]).select('Accuracy');
    //accuracy = accuracy.mean();
    //trial.accuracy = accuracy;

    // Compute payment.
    //var bonus = completion_bonus + Math.ceil(performance_bonus * accuracy * 100) / 100;
    //var total = completion_bonus + performance_bonus;
    //trial.bonus = bonus;
   
     
  //}
//};
