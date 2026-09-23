// get subject id
function getSub(arr) {
  x = arr.find(i => i.includes('sb=')); // go through array, grab element that includes subject code 
  return x;
}

var subj = getSub(window.location.search.split('?')).split('sb=')[1].split("&")[0];
console.log('subject:',subj);



  // get participant_ID
 function getParticipant_ID(arr) {
  y = arr.find(i => i.includes('participant_ID=')); // go through array, grab element that includes subject code 
  return y;
}
//var participant_ID=100 //place holder for prolific pilot
var participant_ID = getParticipant_ID(window.location.search.split('&')).split('participant_ID=')[1];
console.log('participant_ID:',participant_ID);



// get age

function getAge(arr) {
  z = arr.find(i => i.includes('age=')); // go through array, grab element that includes subject age 
  return z;
}
//var age=100 //place holder for prolific pilot
var age = getAge(window.location.search.split('&')).split('age=')[1];
console.log('age:',age);



//------------------------------------//
// Define parameters.
//------------------------------------//

// Define comprehension thresholds.
const max_errors = 0;
const max_loops = 6;
var n_loops = 0;

//---------------------------------------//
// Define useful functions
//---------------------------------------//

// end experiment early if participant exceeds maximum instructions loops
var end_experiment = {
  type: 'call-function',
  func: function() {
    if (n_loops >= max_loops) {
      low_quality = true;
      jsPsych.endExperiment();
    }
  }
}


//------------------------------------//
// Define audio check #1.
//------------------------------------//
 
var instructions_audio = {
  type: 'mrst-instructions',
  pages: [
       {
      prompt: "Welcome to the task, <b>please turn your audio on so you can hear the instructions</b>.",
    view_duration: 500

    }
     ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
}
    
    
var audio_test_01 = {
  type: 'mrst-comprehension',
  prompts: [
    "Click on the word that you just heard",
  ],
  options: [
    ["fish", "tiger", "turtle", "shark"],
  ],
  correct: [
    "fish",
  ],
   
  audio:['./static/audio/fish.mp3'],
  
  on_finish: function() {jsPsych.data.displayData();}
};


var audio_test_01_counter = 0;

var audio_test_01_feedback = {
  type: 'mrst-instructions',
  
  pages: [
    {
      prompt:  function(data) {
        var A1 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(A1)
          if(A1 == 0){
              return '<b>Nice!</b>';
          } else {
              return  '<b>Not quite</b>.';
          }}}
          ],
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var A1 = jsPsych.data.get().last(2).values()[0].num_errors;
    if (A1 == 0) {
      audio_test_01_counter = 0;
    } else {
      audio_test_01_counter++;
    }

       
   }    
};
    

const audio_help = {
  type: 'mrst-instructions',
  pages: [
    {
      prompt: "<p>Let's try this again.<b> Make sure that the audio is on</b> </p>",
    }
  ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
};



const audio_01_help_node = {
    timeline: [
        audio_help,
    ],
    conditional_function: function(data) {

        if (audio_test_01_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const audio_block_01 = {
  timeline: [
     audio_test_01, audio_test_01_feedback, audio_01_help_node 
  ],
  loop_function: function(data) {
  console.log(quiz_1_counter)

    if (audio_test_01_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};


var audio_test_02 = {
  type: 'mrst-comprehension',
  prompts: [
    "Click on the word that you just heard",
  ],
  options: [
    ["fish", "tiger", "turtle", "shark"],
  ],
  correct: [
    "turtle",
  ],
   
  audio:['./static/audio/turtle.mp3'],
  
  on_finish: function() {jsPsych.data.displayData();}
};


var audio_test_02_counter = 0;

var audio_test_02_feedback = {
  type: 'mrst-instructions',
  
  pages: [
    {
      prompt:  function(data) {
        var A2 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(A2 == 0){
              return '<b>Nice!</b>';
          } else {
              return  '<b>Not quite</b>.';
          }}}
          ],
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var A2 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(A2)
    if (A2 == 0) {
      audio_test_02_counter = 0;
    } else {
      audio_test_02_counter++;
    }
   }    
};
    


const audio_02_help_node = {
    timeline: [
        audio_help,
    ],
    conditional_function: function(data) {

        if (audio_test_02_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const audio_block_02 = {
  timeline: [
     audio_test_02, audio_test_02_feedback, audio_02_help_node 
  ],
  loop_function: function(data) {

    if (audio_test_02_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};




//------------------------------------//
// Define instruction block #1.
//------------------------------------//

var instructions_01 = {
  type: 'mrst-instructions',
  pages: [

    {
      prompt: "<p>We are now beginning the <b>Double or Nothing</b> card game.</p><p>Use the buttons below <br>to navigate the instructions.</p>",
      audio: './static/audio/Risk_intro.mp3',
      view_duration: 5000
    },
    {
      prompt: '<p>On every turn of the game, you will choose between two cards</p><p>like the ones above.</p>',
      audio: './static/audio/Risk_2__on_every_turn_of_the_game.mp3',
      show_cards: true,
      view_duration: 5000

    },
    {
      prompt: '<p>One card will always be <b>face up</b>.</p><p>If you choose it, you will always get <b>5 points</b>.</p>',
      show_cards: true,
      choice: 0,
      audio: './static/audio/Risk_3__one_card_will_be_face_up.mp3',
     view_duration: 5000


    },
    {
      prompt: '<p>One card will always have an <b>animal</b> on it.</p><p>If you choose it, there are <u>two possible outcomes</u>.</p>',
      show_cards: true,
      choice: 1,
      audio: './static/audio/Risk_4__one_card_will_always_have_animal_on_it.mp3',
      view_duration: 6000

    },
    {
      prompt: "<p>There's a chance the card turns over and you win <b>10 points</b>. And...</p>",
      show_cards: true,
      choice: 1,
      points: 10,
      face: 'up',
      stimulus: './static/img/all_animals/clear.svg',
      audio: './static/audio/Risk_5__chance_you_win_10_pts.mp3 ',
      view_duration: 5000

    },
    {
      prompt: "<p>... There's a chance the card turns over and you win <b>0 points</b>.</p>",
      show_cards: true,
      choice: 1,
      points: 0,
      face: 'up',
      stimulus: './static/img/all_animals/clear.svg',
      audio: './static/audio/Risk_6__0_points.mp3',
      view_duration: 4000

    },
    {
      prompt: '<p style="line-height: 1.7em;">Therefore, on every turn, you have a choice to make:<br>Choose the face-up card and get 5 points <i>guaranteed</i>, or<br> choose the animal card for <i>a chance</i> of winning 10 points.</p>',
      show_cards: true,
      audio: './static/audio/Risk_7__on_every_turn_you_have_a_choice_to_make.mp3',
      view_duration: 11000
    },
    {
      prompt: '<p style="line-height: 1.7em;">In this game, there will be many different animal cards.<br>Some cards <b>will be lucky</b>. That is, some cards will<br>have a greater chance of giving you 10 points than 0 points.</p>',
      img: './static/img/instructions.png',
      audio: './static/audio/Risk_8__in_this_game_many_diff_animal_cards.mp3',
      view_duration: 10000
    },
    {
      prompt: '<p>Other animal cards <b>will be unlucky</b>. That is, some cards will</p><p>have a greater chance of giving you 0 points than 10 points.</p>',
      img: './static/img/instructions.png',
      audio: './static/audio/Risk_9__other_animal_cards_unlucky.mp3',
      view_duration: 8500
    },
    {
      prompt: "<p>To win the most points, you should try to learn which animal cards</p><p>are lucky or unlucky, and then choose only the lucky cards.</p>",
      audio: './static/audio/Risk_10__to_win_the_most_points.mp3',
      view_duration: 8000
    },
    {
      prompt: "<p>To help you learn, we will flip over the animal card at the end of<br>every turn, even if you did not choose it.</p><p><b>Note:</b> You will only receive points for the card you chose.</p>",
      audio: './static/audio/Risk_11__to_help_you_learn.mp3',
      view_duration: 9000
    },
    {
      prompt: "<p>Now let's practice some turns with the cards above.</p><p>On the next screen, use the <b>left/right arrow keys</b> on your keyboard<br>to choose between the cards.</p>",
      show_cards: true,
      audio: './static/audio/Risk_12__now_let_s_practice.mp3',
      view_duration: 9000
    },
    {
      prompt: '<p>Try to learn if the <i>blue rabbit</i> card is lucky.</p><p>Choose the blue rabbit card if you think it has a greater chance of<br>giving you 10 points than 0 points.</p>',
      show_cards: true,
      audio: './static/audio/Risk_13__try_to_learn_if_the_blue_rabbit.mp3',
      view_duration: 8000
    },
  ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
  on_start: function(trial) {
    pass_message('starting instructions');
  }
}

// Initialize practice counters.
var practice_01_counter = 0;

// Practice trial #1
const practice_01_trial = {
  type: 'mrst-trial',
  stimulus: './static/img/all_animals/rabbit-shape.svg',
  color: '#3d85c690',
  points: '10',
  choice_duration: choice_duration,
  feedback_duration: feedback_duration,
  outcome_duration: outcome_duration,
  data: {block: 0, practice: 1,
      age: age,
      subject: subj,
      participantId: participant_ID,
  },
  on_start: function(trial) {
    trial.points = Math.random() < 0.85 ? 10 : 0;
  },
  on_finish: function(data) {

    // Determine total number of practice trials.
    const k = jsPsych.data.get().filter({trial_type: 'mrst-trial', block: 0, practice: 1}).count();

    // Increment or reset counter.
    if (data.choice == 1 && k > 2) {
      practice_01_counter++;
    } else {
      practice_01_counter = 0;
    }

  }
}

// Practice trial timline #1
const practice_01_node = {
  timeline: [practice_01_trial],
  conditional_function: function() {
    if ( practice_01_counter >= 3 ) {
      return false;
    } else {
      return true;
    }
  }
}

// Practice help #1
const practice_01_help = {
  type: 'mrst-instructions',
  pages: [
    {
      prompt: "<p>Seems like you're having trouble with selecting the better option.</p>",
    },
    {
      prompt: "<p>Try to learn which card (the rabbit card or the face-up card) gives you more points on average.</p><p>Choose the card that you think gives you more points!</p>"
    }
  ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
}

// Practice help node #1
const practice_01_help_node = {
  timeline: [practice_01_help],
  conditional_function: function() {
    if ( practice_01_counter >= 3 ) {
      return false;
    } else {
      return true;
    }
  }
}

// Practice block #1
const practice_block_01 = {
  timeline: [
    practice_01_node, practice_01_node, practice_01_node, practice_01_node,
    practice_01_node, practice_01_node, practice_01_node, practice_01_node,
    practice_01_node, practice_01_help_node
  ],
  loop_function: function(data) {
    if ( practice_01_counter >= 3 ) {
      return false;
    } else {
      return true;
    }
  },
  on_start: function(data) {
    practice_01_counter = 0;
    pass_message('repeating practice 1');
  }
}

//------------------------------------//
// Define practice #2.
//------------------------------------//

var instructions_02 = {
  type: 'mrst-instructions',
  pages: [
      {
      prompt: "Nice practice.",
    },
    {
      prompt: "<p>Great job! As you learned, the rabbit card was lucky and gave you</p><p>10 points <i>most</i> of the time you chose it (but not every time).</p>",
      audio: './static/audio/Risk_14__great_job__learned_blue_rabbit_card.mp3',
      view_duration: 7000
    },
    {
      prompt: "<p>Now let's practice again with a new animal card.</p><p>On the next screen, use the <b>left/right arrow keys</b> on your keyboard<br>to choose between the cards.</p>",
      show_cards: true,
      stimulus: './static/img/all_animals/horse-black-shape.svg',
      color: '#6aa84f91',
      audio: './static/audio/Risk_15__practice_with_new_animal_card.mp3',
      view_duration: 9000
    },
    {
      prompt: '<p>Try to learn if the <i>green horse</i> card is lucky.</p><p>Choose the green horse card if you think it has a greater chance of<br>giving you 10 points than 0 points.</p>',
      show_cards: true,
      stimulus: './static/img/all_animals/horse-black-shape.svg',
      color: '#6aa84f91',
      audio: './static/audio/Risk_16__learn_if_green_horse_is_lucky_or_unlukcy.mp3',
      view_duration: 9000
    },
    {
      prompt: "<p><b>Hint:</b> some animal cards will be unlucky. For unlucky cards,</p><p> you will earn more points on average by choosing the card that's facing up.</p>",
      show_cards: true,
      stimulus: './static/img/all_animals/horse-black-shape.svg',
      color: '#6aa84f91',
      audio: './static/audio/Risk_17__hint.mp3',
      view_duration: 9000
    },
  ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
}

// Initialize practice counters.
var practice_02_counter = 0;

// Practice trial #1
const practice_02_trial = {
  type: 'mrst-trial',
  stimulus: './static/img/all_animals/horse-black-shape.svg',
  color: '#6aa84f91',
  points: '10',
  choice_duration: choice_duration,
  feedback_duration: feedback_duration,
  outcome_duration: outcome_duration,
  data: {block: 0, practice: 2,
       age: age,
      subject: subj,
      participantId: participant_ID,
  },
  on_start: function(trial) {
    trial.points = Math.random() < 0.15 ? 10 : 0;
  },
  on_finish: function(data) {

    // Determine total number of practice trials.
    const k = jsPsych.data.get().filter({trial_type: 'mrst-trial', block: 0, practice: 2}).count();

    // Increment or reset counter.
    if (data.choice == 0 && k > 2) {
      practice_02_counter++;
    } else {
      practice_02_counter = 0;
    }

  }
}

// Practice trial timline #1
const practice_02_node = {
  timeline: [practice_02_trial],
  conditional_function: function() {
    if ( practice_02_counter >= 3 ) {
      return false;
    } else {
      return true;
    }
  }
}

// Practice help #1
const practice_02_help = {
  type: 'mrst-instructions',
  pages: [
      
    {
      prompt: "<p>Seems like you're having trouble with selecting the better option.</p>",
    },
    {
      prompt: "<p>Try to learn which card (the horse card or the face-up card) gives you more points on average.</p><p>Choose the card that gives you more points!.</p>"
    }
  ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
}

// Practice help node #1
const practice_02_help_node = {
  timeline: [practice_02_help],
  conditional_function: function() {
    if ( practice_02_counter >= 3 ) {
      return false;
    } else {
      return true;
    }
  }
}

// Practice block #1
const practice_block_02 = {
  timeline: [
    practice_02_node, practice_02_node, practice_02_node, practice_02_node,
    practice_02_node, practice_02_node, practice_02_node, practice_02_node,
    practice_02_node, practice_02_help_node
  ],
  loop_function: function(data) {
    if ( practice_02_counter >= 3 ) {
      return false;
    } else {
      return true;
    }
  },
  on_start: function(data) {
    practice_02_counter = 0;
    pass_message('repeating practice 2');
  }
}

//------------------------------------//
// Define instruction block #3.
//------------------------------------//

instructions_03 = {
  type: 'mrst-instructions',
  pages: [
        {
      prompt: "Nice practice.",
    },
    {
      prompt: "<p>Good job! Now you know how to play the game.</p><p>Before we start the real game, here are some final details.</p>",
      audio: './static/audio/Risk_18__gj_now_you_know_how_to_play_the_game.mp3',
      view_duration: 6000
    },
    {
      prompt: "<p>The total number of points you've earned by the end of the game<br>will be converted into a <b>performance bonus.</b></p><p>Therefore, you should try to earn as many points as possible.</p>",
      audio: './static/audio/Risk_19__total_points_go_toward_performance_bonus.mp3',
      view_duration: 9000
        
    },
    {
      prompt: "<p>To help you earn as many points as possible, here are <b>2 hints.</b></p><p>Please read each hint carefully.</p>",
      audio: './static/audio/Risk_20__to_help_you_earn.mp3',
      view_duration: 7000
        
    },
    {
      prompt: "<p><b>Hint #1:</b> How lucky or unlucky an animal card is does not change over time.</p><p> This means the luckiness of a card stays the same throughout the game.</p>",
      audio: './static/audio/Risk_21__hint_1_.mp3',
      view_duration: 9000
        
    },
    {
      prompt: "<p><b>Hint #2:</b> Cards can appear on the left or the right side of the screen totally at random.</p> <p> Position does not change how lucky or unlucky a card is.</p>",
      audio: './static/audio/Risk_22__hint_2.mp3',
      view_duration: 10000
        
    },
    {
      prompt: "<p>Next, we will ask you some questions about the game.</p><p>You need to answer all questions correctly to proceed.",
      audio: './static/audio/Risk_23__next_ask_you_some_questions_about_the_game.mp3',
      view_duration: 6000
        
    }

  ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
}

//------------------------------------//
// Define comprehension check.
//------------------------------------//


//------------------------------------//
// Define comprehension check #1.
//------------------------------------//

var quiz_01 = {
  type: 'mrst-comprehension',
  prompts: [
    "<b><i>True</i> or <i>False</i>:</b>&nbsp;&nbsp;Some animal cards are luckier than others.",
  ],
  options: [
    ["True", "False"],
  ],
  correct: [
    "True",
  ],
   
  audio:['./static/audio/Risk_24__checkpoint_q1.mp3'],
  
  view_duration: [3000],
  
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_1_counter = 0;

var quiz_01_feedback = {
  type: 'mrst-instructions',
  
  pages: [
    {
      prompt:  function(data) {
        var Q1 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q1 == 0){
              return '<b>Correct!</b>';
          } else {
              return  '<b>Incorrect</b> Remember, some animal cards will have a greater chance of giving you 10 points than 0 points.';
          }},
          
         audio:function(data) {
        var Q1 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q1 == 0){
              return './static/audio/correct_.mp3';
          } else {
              return './static/audio/incorrect_for_checkpoint_q1.mp3';
          }},
            


        view_duration:function(data) {
        var Q1 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q1 == 0){
              return 300;
          } else {
              return 7000;
          }}}
          ],
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q1 = jsPsych.data.get().last(2).values()[0].num_errors;
    if (Q1 == 0) {
      quiz_1_counter = 0;
    } else {
      quiz_1_counter++;
    }
   }    
};
    

const quiz_help = {
  type: 'mrst-instructions',
  pages: [
    {
      prompt: "<p>Let's try this again.</p>",
    }
  ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
};



const quiz_01_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {

        if (quiz_1_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const quiz_block_01 = {
  timeline: [
     quiz_01, quiz_01_feedback, quiz_01_help_node 
  ],
  loop_function: function(data) {
  console.log(quiz_1_counter)

    if (quiz_1_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};

//------------------------------------//
// Define comprehension check #2.
//------------------------------------//

var quiz_02 = {
  type: 'mrst-comprehension',
  prompts: [
    "<b><i>True</i> or <i>False</i>:</b>&nbsp;&nbsp;I will earn points for the card I <u>did not</u> choose.",
  ],
  options: [
    ["True", "False"],
  ],
  correct: [
    "False",
  ],
  audio:['./static/audio/Risk_25__checkpoint_q2.mp3'],
  
  view_duration: [5000],

  
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_2_counter = 0;

var quiz_02_feedback = {
  type: 'mrst-instructions',
  
  pages: [
    {
      prompt:  function(data) {
        var Q2 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q2 == 0){
              return '<b>Correct!</b>';
          } else {
              return  '<b>Incorrect</b> You will only get points for cards that you choose';
          }},
        audio:function(data) {
        var Q2 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q2 == 0){
              return'./static/audio/correct_.mp3';
          } else {
              return'./static/audio/incorrect_for_checkpoint_q2.mp3';
          }},
        
        view_duration:function(data) {
        var Q2 = jsPsych.data.get().last(1).values()[0].num_errors;
           console.log('Q2:',Q2);

          if(Q2 == 0){
              return 300;
          } else {
              return 4000;
          }}}
          ],
          
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q2 = jsPsych.data.get().last(2).values()[0].num_errors;
    if (Q2 == 0) {
      quiz_2_counter = 0;
    } else {
      quiz_2_counter++;
    }

   }    
};
    



const quiz_02_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_2_counter)

        if (quiz_2_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const quiz_block_02 = {
  timeline: [
     quiz_02, quiz_02_feedback, quiz_02_help_node 
  ],
  loop_function: function(data) {
    if (quiz_2_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};



//------------------------------------//
// Define comprehension check #3.
//------------------------------------//

var quiz_03 = {
  type: 'mrst-comprehension',
  prompts: [
    "<b><i>True</i> or <i>False</i>:</b>&nbsp;&nbsp;How lucky a card is does <u>not</u> change over time.",
  ],
  options: [
    ["True", "False"],
  ],
  correct: [
    "True",
   ],
  audio:['./static/audio/Risk_26__checkpoint_q3.mp3'],
  
  view_duration: [5000],
 
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_3_counter = 0;

var quiz_03_feedback = {
  type: 'mrst-instructions',
  
  pages: [
    {
      prompt:  function(data) {
        var Q3 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q3 == 0){
              return '<b>Correct!</b>';
          } else {
              return  '<b>Incorrect</b> Cards have the same chances of being lucky throughout the game.';
          }},
        audio:function(data) {
        var Q3 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q3 == 0){
              return'./static/audio/correct_.mp3';
          } else {
             return'./static/audio/incorrect_for_checkpoint_q3.mp3';
          }},
          
        view_duration:function(data) {
        var Q3 = jsPsych.data.get().last(1).values()[0].num_errors;
           console.log('Q3:',Q3);

          if(Q3 == 0){
              return 300;
          } else {
              return 6000;
          }}
    }
    
          ],
          
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q3 = jsPsych.data.get().last(2).values()[0].num_errors;
    if (Q3 == 0) {
      quiz_3_counter = 0;
    } else {
      quiz_3_counter++;
    }
   }    
};
    



const quiz_03_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_3_counter)

        if (quiz_3_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const quiz_block_03 = {
  timeline: [
     quiz_03, quiz_03_feedback, quiz_03_help_node 
  ],
  loop_function: function(data) {
    if (quiz_3_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};



//------------------------------------//
// Define comprehension check #4.
//------------------------------------//

var quiz_04 = {
  type: 'mrst-comprehension',
  prompts: [
    "<b><i>True</i> or <i>False</i>:</b>&nbsp;&nbsp;How lucky a card is changes if it is on the left or the right side of the screen.",
  ],
  options: [
    ["True", "False"],
  ],
  correct: [
    "False",
  ],
  audio:[
        './static/audio/Risk_27__checkpoint_q4.mp3'
        ],
        
        view_duration: [7000],

  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_4_counter = 0;

var quiz_04_feedback = {
  type: 'mrst-instructions',
  
  pages: [
    {
      prompt:  function(data) {
        var Q4 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q4 == 0){
              return '<b>Correct!</b>';
          } else {
              return  '<b>Incorrect</b> The location on the screen does not change how lucky a card is.';
          }},
        audio:function(data) {
        var Q4 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q4 == 0){
              return'./static/audio/correct_.mp3';
          } else {
            return './static/audio/incorrect_for_checkpoint_q4.mp3';
          }},
              view_duration:function(data) {
        var Q4 = jsPsych.data.get().last(1).values()[0].num_errors;
           console.log('Q4:',Q4);

          if(Q4 == 0){
              return 300;
          } else {
              return 6000;
          }}
    }
    
          ],
          
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q4 = jsPsych.data.get().last(2).values()[0].num_errors;
    if (Q4 == 0) {
      quiz_4_counter = 0;
    } else {
      quiz_4_counter++;
    }
   }    
};
    



const quiz_04_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_4_counter)

        if (quiz_4_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const quiz_block_04 = {
  timeline: [
     quiz_04, quiz_04_feedback, quiz_04_help_node 
  ],
  loop_function: function(data) {
    if (quiz_4_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};



//------------------------------------//
// Define comprehension check #5.
//------------------------------------//

var quiz_05 = {
  type: 'mrst-comprehension',
  prompts: [
    "<b><i>True</i> or <i>False</i>:</b>&nbsp;&nbsp;The points I earn <u>will</u> affect my performance bonus.",
  ],
  options: [
    ["True", "False"],
  ],
  correct: [
    "True",
  ],
  audio:[
        './static/audio/Risk_28__checkpoint_q5.mp3'
        ],
        
        view_duration: [5000],
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_5_counter = 0;

var quiz_05_feedback = {
  type: 'mrst-instructions',
  
  pages: [
    {
      prompt:  function(data) {
        var Q5 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q5 == 0){
              return '<b>Correct!</b>';
          } else {
              return  '<b>Incorrect</b> How much money you will get at the end of the experiment is affected by the number of points you earn.';
          }},
          audio:function(data) {
        var Q5 = jsPsych.data.get().last(1).values()[0].num_errors;
          if(Q5 == 0){
              return'./static/audio/correct_.mp3';
          } else {
            return './static/audio/incorrect_for_checkpoint_q5.mp3';
          }},
          view_duration:function(data) {
        var Q5 = jsPsych.data.get().last(1).values()[0].num_errors;
           console.log('Q5:',Q5);

          if(Q5 == 0){
              return 300;
          } else {
              return 6000;
          }}
    }
          ],
          
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q5 = jsPsych.data.get().last(2).values()[0].num_errors;
    if (Q5 == 0) {
      quiz_5_counter = 0;
    } else {
      quiz_5_counter++;
    }
   }    
};
    



const quiz_05_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_5_counter)

        if (quiz_5_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const quiz_block_05 = {
  timeline: [
     quiz_05, quiz_05_feedback, quiz_05_help_node 
  ],
  loop_function: function(data) {
    if (quiz_5_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};







//------------------------------------//
// Define instructions block.
//------------------------------------//

// Define instructions loop.
var INSTRUCTIONS = [
  instructions_audio,
  audio_block_01,
  audio_block_02,
 instructions_01,
 practice_block_01,
  instructions_02,
  practice_block_02,
  instructions_03,
  quiz_block_01,
  quiz_block_02,
  quiz_block_03,
  quiz_block_04,
  quiz_block_05
  
]
