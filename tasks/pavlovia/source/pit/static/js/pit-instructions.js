//------------------------------------//
// Define instructions parameters.
//------------------------------------//
// wingdings font unicode codes: https://www.w3schools.com/charsets/ref_utf_misc_symbols.asp

//------------------------------------//
// Define parameters.
//------------------------------------//


// Define comprehension thresholds.
const max_errors = 0;
const max_loops = 6;
var n_loops = 0;

// Define practice trial counts.
const practice_thresh = 30;
var practice_count = 0;
var practice_00_count = 0;
var practice_001_count = 0;
var practice_01_count = 0;
var practice_02_count = 0;
var practice_03_count = 0;
var practice_04_count = 0;


// Define practice block parameters.
const min_practice = 20 //5 noam 1 nov 2022;

// get subject id
function getSub(arr) {
  x = arr.find(i => i.includes('sb=')); // go through array, grab element that includes subject code 
  return x;
}


var subj = getSub(window.location.search.split('?')).split('sb=')[1].split("&")[0];
console.log('subject:',subj);

//var participant_ID=999; //place holder XXXX



// get participant_ID
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

var age = getAge(window.location.search.split('&')).split('age=')[1];
console.log('age:',age);
console.log('age:z',z);


//------------------------------------//
// Define audio test 1.
//------------------------------------//
   
   var instructions_audio = {
  type: 'pit-instructions',
  pages: [
    "Welcome to the <b>Robot Factory</b> game! <br> <b>Please turn your audio on so you can hear the instructions</b>."
    
     ],
  robot_runes: [
    '', 
  ],
  scanner_colors: [
    '#FFFFFF00'
  ],
  
  audio: ['./static/audio/1-second-of-silence.mp3'],
  
  view_duration: [
      3000
      ],
      
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_start: function(trial) {
    pass_message('starting instructions');
  }
}
  

var audio_quiz_01 = {
  type: 'pit-comprehension',
  prompts: [
    "Click on the word that you just heard",
  ],
  options: [
     ["fish", "tiger", "turtle", "shark"],
  ],
  correct: [
    "shark",
  ],
    audio:['./static/audio/shark.mp3'],

  view_duration: [100],

  on_finish: function() {jsPsych.data.displayData();}
};


var audio_1_counter = 0;
console.log(audio_1_counter)


var audio_01_feedback = {
  type: 'pit-instructions',
  
  //pages: [
    //{
      pages:  function(data) {
        var A1 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(A1)
          if(A1 == 0){
              return ["<b>Nice!</b>"];
          } else {
              return  ["<b>Not quite!</b>"];
          }},//}
          //],
              robot_runes: [
    ''
  ],
  scanner_colors: [
    '#FFFFFF00'
],

 audio:['./static/audio/1-second-of-silence.mp3'],
   view_duration: [100],


 
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',
          


   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var A1 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(A1)
    if (A1 == 0) {
      audio_1_counter = 0;
    } else {
      audio_1_counter++;
    }
    console.log(audio_1_counter)
       
   }    
};

    

const quiz_help = {
  type: 'pit-instructions',
  pages: [
      "<p>Let's try this again.</p>",
  ],
    robot_runes: [
    ''
  ],
  audio:['./static/audio/1-second-of-silence.mp3'],
   view_duration: [100],
  scanner_colors: [
    '#FFFFFF00'
],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};



const audio_01_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_1_counter)

        if (audio_1_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const audio_block_01 = {
  timeline: [
      audio_quiz_01, audio_01_feedback, audio_01_help_node 
  ],
  loop_function: function(data) {
  console.log(audio_1_counter)

    if (audio_1_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};

//------------------------------------//
// Define audio test 2.
//------------------------------------//
   
 

var audio_quiz_02 = {
  type: 'pit-comprehension',
  prompts: [
    "Click on the word that you just heard",
  ],
  options: [
     ["fish", "tiger", "turtle", "shark"],
  ],
  correct: [
    "tiger",
  ],
    audio:['./static/audio/tiger.mp3'],

  view_duration: [100],

  on_finish: function() {jsPsych.data.displayData();}
};


var audio_2_counter = 0;
console.log(audio_2_counter)


var audio_02_feedback = {
  type: 'pit-instructions',
  
  //pages: [
    //{
      pages:  function(data) {
        var A2 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(A2)
          if(A2 == 0){
              return ["<b>Nice!</b>"];
          } else {
              return  ["<b>Not quite!</b>"];
          }},//}
          //],
              robot_runes: [
    ''
  ],
  scanner_colors: [
    '#FFFFFF00'
],

 audio:['./static/audio/1-second-of-silence.mp3'],
   view_duration: [100],


 
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',
          


   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var A2 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(A2)
    if (A2 == 0) {
      audio_2_counter = 0;
    } else {
      audio_2_counter++;
    }
    console.log(audio_2_counter)
       
   }    
};



const audio_02_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(audio_2_counter)

        if (audio_2_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const audio_block_02 = {
  timeline: [
     audio_quiz_02, audio_02_feedback, audio_02_help_node 
  ],
  loop_function: function(data) {
  console.log('audio_2_counter',audio_2_counter)

    if (audio_2_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};


//------------------------------------//
// Define instructions text.
//------------------------------------//


var instructions_01_1 = {
  type: 'pit-instructions',
  pages: [
    "In this game, your job as a factory worker is to inspect the different types of robots and earn as many points as possible.",
    "You can tell the different types of robots apart by looking at the symbols on their chest.",
    "For example, this type of robot can be recognized by its <b>star</b> symbol.",
    "While this type of robot can be recognized by its <b> comet</b>  symbol.",
    "Always  pay close attention to the robot's symbol. <br> It will help you do well in the game .",
    "When a robot enters the scanner, you need to decide which action to take.",
    `You can choose between two actions: You can <b>attend</b> to the robot or you can <b>ignore</b> the robot.`,
    'Some types of robots need to be attended to while other types of robots need to be ignored.', 
    'Your goal is to learn which action is best for each type of robot.',
   `To <b>attend</b> to the robot, push the <b>space bar</b> key on the keyboard with the pointer finger on your dominant hand.`,
   `Rest your pointer finger on the <b>space bar</b> throughout the experiment.`,
   "When you attend to the robot, make sure you press while the scanner light is on, not before that.",
   `Let's practice with this type of robot that needs your attention.`,
   `Push the space bar when this type of robot enters the scanner.`],
  robot_runes: [
     '', '','&#10030','&#9732', '',  '',  '',  '',  '','','', '','&#9784', '&#9784', 
  ],
  scanner_colors: [
    '#FFFFFF00', '#FFFFFF00', '#FFFFF080', '#FFFFF080','#FFFFFF00','#FFFFFF00','#FFFFFF00','#FFFFFF00','#FFFFFF00','#FFFFFF00','#FFFFFF00', '#FFFFF080', '#FFFFF080',
    '#FFFFF080','#FFFFF080'
  ],
  audio: ['./static/audio/PIT_2_in_this_game.mp3','./static/audio/PIT_3_you_can_tell.mp3','./static/audio/PIT_4_forexamplestar.mp3','./static/audio/PIT_5_whilecomet.mp3','./static/audio/PIT_6_alwayspay.mp3',
  './static/audio/PIT_7_whenrobotenters.mp3','./static/audio/PIT_8_youcanchoosebtwn_1.mp3','./static/audio/PIT_9_sometypesattendothersignored_1.mp3','./static/audio/PIT_10_yourgoal.mp3','./static/audio/PIT_11_toattend.mp3',
  './static/audio/PIT_12_restpointerfinger.mp3','./static/audio/PIT_13_whenyouattend.mp3','./static/audio/PIT_14_let_spracticeattend.mp3','./static/audio/PIT_15_pushspacebarwhen.mp3'],
  
  view_duration: [
      7000,5000,6000,5000,5000,5000,5000,6000,6000,5000,7000,4000,6000,4000,4000
      ],
  
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_start: function(trial) {
    pass_message('starting instructions');
  }
}
   


   
   
   var instructions_01_2 = {
  type: 'pit-instructions',
  pages: [
    "<b>Good job!</b> You now know how to attend to the factory's robots.",
    "If you decide  to <b>ignore</b> robots, just don't press any button.",
    `Let's practice with this type of robot that <b>needs to be ignored</b>.`,
   "When this robot enters the scanner, do not press any buttons."
    
     ],
  robot_runes: [
    '', '', '&#9854',  '&#9854', '&#9854', 
  ],
  scanner_colors: [
    '#FFFFFF00', '#FFFFFF00', '#FFFFF080', '#FFFFF080', '#FFFFF080', '#FFFFF080',
    '#FFFFF080','#FFFFF080'
  ],
  
  audio: ['./static/audio/PIT_16_goodjobattend.mp3','./static/audio/PIT_17_ifyoudecideignore.mp3','./static/audio/PIT_18_letspraticeignore.mp3','./static/audio/PIT_19_whenthisdon_tpressanybuttons.mp3'],
  
  view_duration: [
      4000,5000,4000,5000
      ],
      
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_start: function(trial) {
    pass_message('starting instructions');
  }
}
  
   
   var instructions_01_3 = {
  type: 'pit-instructions',
  pages: [
    "<b>Nice</b>. Now you know how to attend to robots and how to ignore them.",
    `In our factory, some types of robots are <b> <font color=${outcome_color_win}> Point Givers</font></b> and some are <b><font color=${outcome_color_lose}> Point Takers</font></b>.`,
    `<b> <font color=${outcome_color_win}>Point Givers </font></b> will either <b>give</b> you 10 points or not give you any points.`,
    `<b><font color=${outcome_color_lose}>Point Takers</font></b> will either <b>take</b> 10 of your points or not take any of your points.`,
    `For the <b> <font color=${outcome_color_win}>Point Givers</font></b>, you want to earn as many points as possible.`,
    `For the <b><font color=${outcome_color_lose}>Point Takers</font></b>, you want to stop them from taking your points.`,
    `If the scanner is <b><font color=${outcome_color_win}>${instr_color_win}</font></b>, the robot is a <b><font color=${outcome_color_win}> Point Giver</font></b>.<br>`,
    `That means if you choose the correct action for that type of robot, it will usually give you 10 points.`,
    `If you choose the wrong action for a <b><font color=${outcome_color_win}>Point Giver</font></b>, it will usually not give you any points.`,
    `However, sometimes <b><font color=${outcome_color_win}>Point Givers </font></b> will not give you any points for a correct action.`,
    ` And sometimes they will still give you 10 points even if you take an incorrect action.`,
     `If the scanner is <b><font color=${outcome_color_lose}>${instr_color_lose}</font></b>, the robot is a <b><font color=${outcome_color_lose}>Point Taker</font></b>.`,
     `If you choose the correct action for a <b><font color=${outcome_color_lose}>Point Taker</font></b>, the robot will usually not take any of your points.`,
    `If you choose the wrong action for a <b><font color=${outcome_color_lose}>Point Taker</font></b>, the robot will usually take 10 points from you.`,
    `However, sometimes <b><font color=${outcome_color_lose}>Point Takers</font></b> will still take away 10 points after you perform the correct action.`,
    `And sometimes they will not take away any points, even if you take an incorrect action.`,
    `Let's practice with a  <b><font color=${outcome_color_win}>Point Giver</font></b>. Try to learn the correct action for this type of robot.`,
    `Remember, to attend to the robot, press the space bar. To ignore it, do not press anything.` 

  ],
  robot_runes: [
    '', '', '','','','' ,'',  '','', '', '', '','','','','','&#9776','&#9776'
  ],
  scanner_colors: [
    '#FFFFFF00','#FFFFFF00', '#FFFFFF00', '#FFFFFF00', '#FFFFFF00', '#FFFFFF00', scanner_color_win,scanner_color_win, scanner_color_win, scanner_color_win,
    scanner_color_win, scanner_color_lose, scanner_color_lose,scanner_color_lose, scanner_color_lose,scanner_color_lose, scanner_color_win,scanner_color_win 
  ],
  audio: ['./static/audio/PIT_20_nice.mp3','./static/audio/PIT_21_inourfactory.mp3','./static/audio/PIT_22_pointgiverswill.mp3','./static/audio/PIT_23_pointtakerswill.mp3',
  './static/audio/PIT_24_forthepointgivers.mp3','./static/audio/PIT_25_forthepointtakers.mp3','./static/audio/PIT_26_ifthescannerisblue.mp3','./static/audio/PIT_27_thatmeansusuallygive.mp3',
  './static/audio/PIT_28_ifyouchoosewrongactionpointgiver.mp3','./static/audio/PIT_29_howeverpointgiverswillnot.mp3','./static/audio/PIT_30_andsometimestheywill.mp3','./static/audio/PIT_31_ifscannerisred.mp3',
  './static/audio/PIT_32_ifchoosecorrectactionpointtaker.mp3','./static/audio/PIT_33_ifchoosewrongpointtaker.mp3','./static/audio/PIT_34_howeversometimespointtakerswill.mp3','./static/audio/PIT_35_andsometimeswillnottakeaway.mp3',
  './static/audio/PIT_36_letspracticewithpointgiver.mp3','./static/audio/PIT_37_remembertoattend_1_.mp3'],
  
  view_duration: [
      5000,6000,5000,5000,5000,5000,4000,7000,6000,5000,6000,4000,6000,6000,6000,6000,6000,6000 
      ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
  on_start: function(trial) {
    pass_message('starting instructions');
  }
}

var instructions_02 = {
  type: 'pit-instructions',
  pages: [`Good job! You might have learned that this type of robot needed to be attended to.`,
  `Because the robot was a <b><font color=${outcome_color_win}>Point Giver</font></b>, most of the time, you <b>won</b> 10 points if you attended to it.`,
  `You also might have noticed that even though attending was the correct action for this robot, it did not give you points every time you attended to it.`,
  `In the real game it will be the same. <br> The correct action for a <b><font color=${outcome_color_win}>Point Giver</font></b> will earn you points <b>MOST</b> of the time, but not <b>ALL</b> the time.`,  
`Now let's practice with another type of a <b> <font color=${outcome_color_win}>Point Giver</font></b>.<br>Try to learn whether you should attend to or ignore it.`
    ],
  robot_runes: [
    '&#9776;','&#9776','&#9776','&#9776','&#9761'  
  ],
  scanner_colors: [
    scanner_color_win, scanner_color_win,scanner_color_win,scanner_color_win,scanner_color_win
  ],
  
  audio: ['./static/audio/PIT_38_goodjobattendedto.mp3','./static/audio/PIT_39_becausepointgiver.mp3','./static/audio/PIT_40_youalsomighthavenoticed.mp3','./static/audio/PIT_41_intherealgame.mp3',
  './static/audio/PIT_42_nowletspracticeanothertypeofPG.mp3'],
  
  view_duration: [
      5000,6000,9000,8000,7000
      ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next"
}

var instructions_03 = {
  type: 'pit-instructions',
  pages: [
     `<b>Great!</b> You might have learned that you should ignore this type of robot.`,
    ` Because this robot was a <b><font color=${outcome_color_win}>Point Giver</font></b>, most of the time, the robot gave you points if you performed this action.`,
    `Let's practice with a <b><font color=${outcome_color_lose}>Point Taker</font></b> robot.`,
    `As a reminder, <b><font color=${outcome_color_lose}>Point Takers</font></b> will usually not take points if you take the right action, and they will usually take away 10 points if you take the wrong action.`,
    `Try to learn if you should attend to  or ignore this type of robot.`
    ],

  robot_runes: [
    '&#9761','&#9761','&#9826','&#9826','&#9826'
  ],
  scanner_colors: [
    scanner_color_win, scanner_color_win, scanner_color_lose,scanner_color_lose, scanner_color_lose
  ],
  
  audio: ['./static/audio/PIT_43_greatmighthavelearnedignore.mp3','./static/audio/PIT_44_becausePGrobotgavepts.mp3','./static/audio/PIT_45_letspracticewithPTrobot.mp3',
  './static/audio/PIT_46_asareminderPTswillnot.mp3','./static/audio/PIT_47_trytolearnattendorignore.mp3'
  ],
  
  view_duration: [
      4000,6000,3000,10000,4000,
      ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
};

var instructions_04 = {
  type: 'pit-instructions',
  pages: [
    `OK, good. As you might have learned, it was better for you to ignore this type of robot.`,
    `Because this robot was a <b><font color=${outcome_color_lose}>Point Taker</font></b>, most of the time, ignoring this type of robot helped you to avoid losing points.`,
    `Now let's practice with another type of <b><font color=${outcome_color_lose}>Point Taker</font></b> robot.`,
    `Try to learn whether you should attend to this type of robot or ignore it.`
    ],
    robot_runes: [
    '&#9826','&#9826','&#9789','&#9789'
  ],
  scanner_colors: [
    scanner_color_lose, scanner_color_lose,scanner_color_lose,scanner_color_lose 
  ],
  
   audio: ['./static/audio/PIT_48_okgood.mp3','./static/audio/PIT_49_becauserobotswasPT.mp3','./static/audio/PIT_50_nowletspracticeanothertypeofPT.mp3',
  './static/audio/PIT_51_trytolearnattendorignore.mp3'
  ],
  
  view_duration: [
      6000,8000,4000,4000
      ],
  show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
};

var instructions_05 = {
  type: 'pit-instructions',
  pages: [
    `Great job! You might have learned that this type of robot should be attended to.`,
    `When you attended to this type of robot, it usually did not take any points from you.`,
    `<b>Remember:</b> Most of the time when you take the correct action, <br> a <b><font color=${outcome_color_win}>Point Giver</font></b> will give you points, <br>and a <b><font color=${outcome_color_lose}>Point Taker</font></b> will not take your points,<br> but this will not happen <b>EVERY</b> time you make the correct choice`,
    `On every trial, pay close attention both the color of the light <b>AND</b> the symbol on the robot's chest.`,
    `The symbol tells you the type of robot. For each type, you need to learn whether attending or ignoring is better.`,
    `The color tells you whether the robot is a <b><font color=${outcome_color_win}>Point Giver</font></b> or a <b><font color=${outcome_color_lose}>Point Taker</font></b>.`,
    `The symbol tells you the type of robot so that you can learn which types need to be attended to and which types need to be ignored.`,
    "At the end of the task, the total number of points you have <br>earned will be converted into <b>bonus money.</b>",
    "Now, we will ask you some questions about the task."
  ],
  robot_runes: [
    '&#9789','&#9789','','','&#9797','','&#9797',''
  ],
  scanner_colors: [
    scanner_color_lose,scanner_color_lose, '', '', '', 'FFFFF080', '' , '','','',''
    ],
      audio: ['./static/audio/PIT_52_greatjoblearnedattendedto.mp3','./static/audio/PIT_53_whenattendedtodidnottakepoints.mp3','./static/audio/PIT_54_remembermostofthetime.mp3','./static/audio/PIT_55_oneverytrialpaycloseattention.mp3',
  './static/audio/PIT_56_symboltellsyou.mp3','./static/audio/PIT_57_colortellsyou.mp3','./static/audio/PIT_58_symboltellyoutypeofrobotlearnwhichtypesneedtobe.mp3','./static/audio/PIT_59_atendoftaskbonusmoney.mp3',
  './static/audio/PIT_60_nowaskquestionsabouttask.mp3', 
  ],
  
  view_duration: [
      6000,4000,8000,4000,6000,8000,4000,4000,3000
      ],
      
      show_clickable_nav: true,
  button_label_previous: "Prev",
  button_label_next: "Next",
};

//------------------------------------//
// Define practice blocks.
//------------------------------------//

// Function to end experiment if maximum practice trials
// have been reached
var attention_check = {
  type: 'call-function',
  func: function(){},
  on_finish: function(trial) {
    if (low_quality) { 
   jsPsych.endExperiment(`Unfortunately, you did not pass the practice required to start the Robot Factory task. Please follow the approved study instructions for stopping the task or contacting the study team.`
); }
  }
};



//const safe_correct = ["+10", "+10", "+10", "0"];
//const random = Math.floor(Math.random() * safe_correct.length);

  
  
  
    const practice_00_trial_1 ={
  type: 'pit-trial',
  robot_rune: '&#9784;',
  scanner_color: '#FFFFF080',
  outcome_color: outcome_color_win,
  outcome_correct:'&#10004',
  outcome_incorrect: '&#10060',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 0,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
  };
  
   
  const practice_00_help = {
  type: 'pit-instructions',
  pages: [

"<p><p>Seems like you're having trouble with selecting the right action for this robot.</p>",
     
"<p>Just press the space bar every time this type of robot is entering the scanner.</p>",

  ],
    robot_runes: [
    '&#9784', '&#9784'
  ],
  scanner_colors: [
    '#FFFFFF00','#FFFFFF00','#FFFFFF00'
],
  audio: ['./static/audio/PIT_feedback_seemslike.mp3','./static/audio/PIT2_justpressSB.mp3'],
  
  view_duration: [
      5000,8000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

 const practice_00_help_node = {
    timeline: [
        practice_00_help,
    ],
    conditional_function: function(data) {
    console.log(practice_count);
    console.log(practice_00_count);

        if (practice_00_count==6 ) {
      return true;
    } else {
      return false;
    }
}}; 
  
  var practice_00 = {
  timeline: [practice_00_trial_1,
  practice_00_help_node
],
  loop_function: function(data) {

    // Increment counter. Check for experiment termination.
    practice_count++;
    practice_00_count++;
    console.log(practice_count);
    console.log(practice_00_count);

    if ( practice_00_count > 7 ) {
      practice_00_count = 0;
    }

    // Extract accuracy from practice trials (type 1).
    const reducer = (accumulator, currentValue) => accumulator + currentValue;
    const practice = jsPsych.data.get().filter({practice: 0}).select('accuracy').values;
    const score = practice.slice(Math.max(practice.length - 3, 0)).reduce(reducer);

    // If less than 4 practice trials: loop.
    if ( practice.length < 5){ //min_practice ) {
      return true;

    // If last 3 not at all correct: loop.
    } else if ( score < 3 ) {
      return true;

    // Otherwise: end practice.
    } else {
      return false;
    }
  }
}





  const practice_001_trial_1 ={
  type: 'pit-trial',
  robot_rune: '&#9854;',
  scanner_color: '#FFFFF080',
  outcome_color: outcome_color_win,
  outcome_correct:'&#10004',
  outcome_incorrect: '&#10060',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 01,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
  };
  
   
  const practice_001_help = {
  type: 'pit-instructions',
  pages: [

"<p><p>Seems like you're having trouble with selecting the right action for this robot.</p>",
     
"<p>Just don't press any button when this type of robot is entering the scanner.</p>",

  ],
    robot_runes: [
    '&#9854', '&#9854'
  ],
  scanner_colors: [
    '#FFFFFF00','#FFFFFF00','#FFFFFF00'
],
audio: ['./static/audio/PIT_feedback_seemslike.mp3','./static/audio/PIT1_dontpressSB.mp3'],
  
  view_duration: [
      5000,8000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_001_help_node = {
    timeline: [
        practice_001_help,
    ],
    conditional_function: function(data) {
    

        if (practice_001_count==6 ) {
      return true;
    } else {
      return false;
    }
}};
  
  
  var practice_001 = {
  timeline: [practice_001_trial_1,
  practice_001_help_node
],
  loop_function: function(data) {

    // Increment counter. Check for experiment termination.
    practice_count++;
    practice_001_count++;
    console.log(practice_count);
    console.log(practice_001_count);

    if ( practice_001_count > 7 ) {
      practice_001_count = 0;
    }

    // Extract accuracy from practice trials (type 1).
    const reducer = (accumulator, currentValue) => accumulator + currentValue;
    const practice = jsPsych.data.get().filter({practice: 01}).select('accuracy').values;
    const score = practice.slice(Math.max(practice.length - 3, 0)).reduce(reducer);

    // If less than 4 practice trials: loop.
    if ( practice.length <  5){//min_practice ) {
      return true;

    // If last 3 not at all correct: loop.
    } else if ( score < 3 ) {
      return true;

    // Otherwise: end practice.
    } else {
      return false;
    }
  }
}
      
// Practice block (GW robot)
  const practice_01_trial_1 ={
  type: 'pit-trial',
  robot_rune: '&#9776;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct:'+10',
  outcome_incorrect: '0',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 1,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
  };
  
  const practice_01_trial_2 ={
  type: 'pit-trial',
  robot_rune: '&#9776;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct:'+10',
  outcome_incorrect: '0',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 1,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
  };
  
  const practice_01_trial_3 ={
  type: 'pit-trial',
  robot_rune: '&#9776;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct:'+10',
  outcome_incorrect: '0',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 1,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
  };
  
  const practice_01_trial_4 ={
  type: 'pit-trial',
  robot_rune: '&#9776;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct:'0',
  outcome_incorrect: '+10',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 1,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
  };
 
 
  const practice_01_trial_5 ={
  type: 'pit-trial',
  robot_rune: '&#9776;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct:'+10',
  outcome_incorrect: '0',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 1,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
  };
 
  const practice_01_help = {
  type: 'pit-instructions',
  pages: [
     
"<p>Seems like you're having trouble with selecting the right action for this robot.</p>",
"<p>Try to learn if you should attend or ignore this type of robot.</p>",
"<p>Pay close attention to your selection. In case you will not be able to learn the proper action for this type robot the experiment will end.</p>"

  ],
    robot_runes: [
    '&#9776','&#9776','&#9776'
  ],
  scanner_colors: [
    '#FFFFFF00','#FFFFFF00','#FFFFFF00'
],
audio: ['./static/audio/PIT_feedback_seemslike.mp3','./static/audio/PIT3_trytolearn.mp3','./static/audio/PIT_feedback_paycloseattn.mp3'],
  
  view_duration: [
      5000,5000,5000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_01_help_node = {
    timeline: [
        practice_01_help,
    ],
    conditional_function: function(data) {
    

        if (practice_01_count==4 ) {
      return true;
    } else {
      return false;
    }
}};






  const practice_01_fail = {
  type: 'pit-instructions',
  pages: [
      `<p>Unfortunately, you did not pass the practicet phase</p>
    <p><a href="#">Please click here</a>.</p>`,
  ],
    robot_runes: [
    '&#9776'
  ],
  scanner_colors: [
    '#FFFFFF00'
],
audio: [],
  
  view_duration: [
      50000000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_01_fail_node = {
    timeline: [
        practice_01_fail,
    ],
    conditional_function: function(data) {
    

        if (practice_01_count==practice_thresh ) {
      return true;
    } else {
      return false;
    }
}};

var practice_01 = {
  timeline: [practice_01_trial_1,
  practice_01_trial_2,
  practice_01_trial_3,
  practice_01_trial_4,
  practice_01_trial_5,
 // practice_01_help_node,
  //practice_01_fail_node
],
  loop_function: function(data) {

    // Increment counter. Check for experiment termination.
    practice_count++;
    practice_01_count++;
    console.log(practice_count);
    console.log(practice_01_count);

 //   if ( practice_01_count > practice_thresh ) {
   //    var session_end_link = 'YOUR_POST_EXPERIMENT_REDIRECT_URL';
    //  low_quality = true;
     // return false;
//    }

    // Extract accuracy from practice trials (type 1).
    const reducer = (accumulator, currentValue) => accumulator + currentValue;
    const practice = jsPsych.data.get().filter({practice: 1}).select('accuracy').values;
    const score = practice.slice(Math.max(practice.length - 4, 0)).reduce(reducer);

    // If less than 4 practice trials: loop.
    if ( practice.length < min_practice ) {
      return true;

    // If last 3 not at all correct: loop.
  //  } else if ( score < 4 ) {
    //  return true;

    // Otherwise: end practice.
    } else {
      return false;
    }

  }
}

// Practice block (NGW robot)
const practice_02_trial_1 = {
  type: 'pit-trial',
  robot_rune: '&#9761;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct: '+10',
  outcome_incorrect: '0',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 2,
      age: age,
      subject: subj,
      participantId: participant_ID
  }
  
}

const practice_02_trial_2 = {
  type: 'pit-trial',
  robot_rune: '&#9761;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct: '+10',
  outcome_incorrect: '0',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 2,
      age: age,
      subject: subj,
      participantId: participant_ID
  }
  
};

const practice_02_trial_3 = {
  type: 'pit-trial',
  robot_rune: '&#9761;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct: '+10',
  outcome_incorrect: '0',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 2,
       age: age,
      subject: subj,
      participantId: participant_ID
  }
  
};

const practice_02_trial_4 = {
  type: 'pit-trial',
  robot_rune: '&#9761;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct: '0',
  outcome_incorrect: '+10',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 2,
       age: age,
      subject: subj,
      participantId: participant_ID
  }
  
};

const practice_02_trial_5 = {
  type: 'pit-trial',
  robot_rune: '&#9761;',
  scanner_color: scanner_color_win,
  outcome_color: outcome_color_win,
  outcome_correct: '+10',
  outcome_incorrect: '0',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 2,
       age: age,
      subject: subj,
      participantId: participant_ID
  }
  
};

const practice_02_help = {
  type: 'pit-instructions',
  pages: [
     
"<p>Seems like you're having trouble with selecting the right action for this robot.</p>",
"<p>Try to learn if you should attend or ignore this type of robot.</p>",
"<p>Pay close attention to your selection. In case you will not be able to learn the proper action for this type robot the experiment will end.</p>"

  ],
    robot_runes: [
    '&#9761','&#9761','&#9761'
  ],
  scanner_colors: [
    '#FFFFFF00','#FFFFFF00','#FFFFFF00'
],
audio: ['./static/audio/PIT_feedback_seemslike.mp3','./static/audio/PIT3_trytolearn.mp3','./static/audio/PIT_feedback_paycloseattn.mp3'],
  
  view_duration: [
      5000,5000,5000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_02_help_node = {
    timeline: [
        practice_02_help,
    ],
    conditional_function: function(data) {
    

        if (practice_02_count==4 ) {
      return true;
    } else {
      return false;
    }
}};



  const practice_02_fail = {
  type: 'pit-instructions',
  pages: [
      `<p>Unfortunately, you did not pass the practicet phase</p>
    <p><a href="#">Please click here</a>.</p>`,
  ],
    robot_runes: [
    '&#9776'
  ],
  scanner_colors: [
    '#FFFFFF00'
],
audio: [],
  
  view_duration: [
      50000000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_02_fail_node = {
    timeline: [
        practice_02_fail,
    ],
    conditional_function: function(data) {
    

        if (practice_02_count==practice_thresh ) {
      return true;
    } else {
      return false;
    }
}};


var practice_02 = {
  timeline: [practice_02_trial_1,
  practice_02_trial_2,
  practice_02_trial_3,
  practice_02_trial_4,
  practice_02_trial_5],
 // practice_02_help_node,
  //practice_02_fail_node],
  loop_function: function(data) {

    // Increment counter. Check for experiment termination.
    practice_count++;
     practice_02_count++
         console.log(practice_02_count);

    if (practice_02_count > practice_thresh ) {
     var session_end_link = 'YOUR_POST_EXPERIMENT_REDIRECT_URL';
      low_quality = true;
      return false;
    }
    


    // Extract accuracy from practice trials (type 2).
    const reducer = (accumulator, currentValue) => accumulator + currentValue;
    const practice = jsPsych.data.get().filter({practice: 2}).select('accuracy').values;
    const score = practice.slice(Math.max(practice.length - 4, 0)).reduce(reducer);

    // If less than 4 practice trials: loop.
    if ( practice.length < min_practice ) {
      return true;

    // If last 3 not at all correct: loop.
  //  } else if ( score < 4 ) {
    //  return true;

    // Otherwise: end practice.
    } else {
      return false;
    }

  }
};

// Practice block (NGW robot)
const practice_03_trial_1 = {
  type: 'pit-trial',
  robot_rune: '&#9826;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 3,
       age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_03_trial_2 = {
  type: 'pit-trial',
  robot_rune: '&#9826;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 3,
       age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_03_trial_3 = {
  type: 'pit-trial',
  robot_rune: '&#9826;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 3,
       age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_03_trial_4 = {
  type: 'pit-trial',
  robot_rune: '&#9826;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '-10',
  outcome_incorrect: '0',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 3,
       age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_03_trial_5 = {
  type: 'pit-trial',
  robot_rune: '&#9826;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: -1,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 3,
       age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_03_help = {
  type: 'pit-instructions',
  pages: [
     
"<p>Seems like you're having trouble with selecting the right action for this robot.</p>",
"<p>Try to learn if you should attend or ignore this type of robot.</p>",
"<p>Pay close attention to your selection. In case you will not be able to learn the proper action for this type robot the experiment will end.</p>"

  ],
    robot_runes: [
    '&#9826','&#9826','&#9826'
  ],
  scanner_colors: [
    '#FFFFFF00','#FFFFFF00','#FFFFFF00'
],

audio: ['./static/audio/PIT_feedback_seemslike.mp3','./static/audio/PIT3_trytolearn.mp3','./static/audio/PIT_feedback_paycloseattn.mp3'],
  
  view_duration: [
      5000,5000,5000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_03_help_node = {
    timeline: [
        practice_03_help,
    ],
    conditional_function: function(data) {
    

        if (practice_03_count==4 ) {
      return true;
    } else {
      return false;
    }
}};







  const practice_03_fail = {
  type: 'pit-instructions',
  pages: [
      `<p>Unfortunately, you did not pass the practicet phase</p>
    <p><a href="#">Please click here</a>.</p>`,
  ],
    robot_runes: [
    '&#9776'
  ],
  scanner_colors: [
    '#FFFFFF00'
],
audio: [],
  
  view_duration: [
      50000000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_03_fail_node = {
    timeline: [
        practice_03_fail,
    ],
    conditional_function: function(data) {
    

        if (practice_03_count==practice_thresh ) {
      return true;
    } else {
      return false;
    }
}};




var practice_03 = {
  timeline: [practice_03_trial_1,
  practice_03_trial_2,
  practice_03_trial_3,
  practice_03_trial_4,
  practice_03_trial_5],
 // practice_03_help_node,
  //practice_03_fail_node],
  loop_function: function(data) {

    // Increment counter. Check for experiment termination.
    practice_count++;
     practice_03_count++
         console.log(practice_03_count);

    if ( practice_03_count > practice_thresh ) {
      var session_end_link = 'YOUR_POST_EXPERIMENT_REDIRECT_URL';
      low_quality = true;
      return false;
    }

    // Extract accuracy from practice trials (type 3).
    const reducer = (accumulator, currentValue) => accumulator + currentValue;
    const practice = jsPsych.data.get().filter({practice: 3}).select('accuracy').values;
    const score = practice.slice(Math.max(practice.length - 4, 0)).reduce(reducer);

    // If less than 4 practice trials: loop.
    if ( practice.length < min_practice ) {
      return true;

    // If last 3 not at all correct: loop.
   // } else if ( score < 4 ) {
     // return true;

    // Otherwise: end practice.
    } else {
      return false;
    }

  }
};

// Practice block (GAL robot)
const practice_04_trial_1 = {
  type: 'pit-trial',
  robot_rune: '&#9789;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 4,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_04_trial_2 = {
  type: 'pit-trial',
  robot_rune: '&#9789;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 4,
       age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_04_trial_3 = {
  type: 'pit-trial',
  robot_rune: '&#9789;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 4,
       age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_04_trial_4 = {
  type: 'pit-trial',
  robot_rune: '&#9789;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '-10',
  outcome_incorrect: '0',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 4,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
};

const practice_04_trial_5 = {
  type: 'pit-trial',
  robot_rune: '&#9789;',
  scanner_color: scanner_color_lose,
  outcome_color: outcome_color_lose,
  outcome_correct: '0',
  outcome_incorrect: '-10',
  correct: key_go,
  valid_responses: [key_go],
  trial_duration: trial_duration,
  feedback_duration: feedback_duration,
  data: {block: 0, practice: 4,
      age: age,
      subject: subj,
      participantId: participant_ID
  },
};


const practice_04_help = {
  type: 'pit-instructions',
  pages: [
     
"<p>Seems like you're having trouble with selecting the right action for this robot.</p>",
"<p>Try to learn if you should attend or ignore this type of robot.</p>",
"<p>Pay close attention to your selection. In case you will not be able to learn the proper action for this type robot the experiment will end.</p>"

  ],
    robot_runes: [
    '&#9789','&#9789','&#9789'
  ],
  scanner_colors: [
    '#FFFFFF00','#FFFFFF00','#FFFFFF00'
],
audio: ['./static/audio/PIT_feedback_seemslike.mp3','./static/audio/PIT3_trytolearn.mp3','./static/audio/PIT_feedback_paycloseattn.mp3'],
  
  view_duration: [
      5000,5000,5000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_04_help_node = {
    timeline: [
        practice_04_help,
    ],
    conditional_function: function(data) {
    

        if (practice_04_count==4 ) {
      return true;
    } else {
      return false;
    }
}};










  const practice_04_fail = {
  type: 'pit-instructions',
  pages: [
      `<p>Unfortunately, you did not pass the practicet phase</p>
    <p><a href="#">Please click here</a>.</p>`,
  ],
    robot_runes: [
    '&#9776'
  ],
  scanner_colors: [
    '#FFFFFF00'
],
audio: [],
  
  view_duration: [
      50000000
      ],
  button_label_previous: 'Prev',
  button_label_next: 'Next',
};

const practice_04_fail_node = {
    timeline: [
        practice_04_fail,
    ],
    conditional_function: function(data) {
    

        if (practice_04_count==practice_thresh ) {
      return true;
    } else {
      return false;
    }
}};



var practice_04 = {
  timeline: [practice_04_trial_1,
  practice_04_trial_2,
  practice_04_trial_3,
  practice_04_trial_4,
  practice_04_trial_5],
  //practice_04_help_node,
  //practice_04_fail_node],
  loop_function: function(data) {

    // Increment counter. Check for experiment termination.
    practice_count++;
     practice_04_count++
         console.log(practice_04_count);

    if ( practice_04_count > practice_thresh ) {
      var session_end_link = 'YOUR_POST_EXPERIMENT_REDIRECT_URL';
      low_quality = true;
      return false;
    }

    // Extract accuracy from practice trials (type 4).
    const reducer = (accumulator, currentValue) => accumulator + currentValue;
    const practice = jsPsych.data.get().filter({practice: 4}).select('accuracy').values;
    const score = practice.slice(Math.max(practice.length - 4, 0)).reduce(reducer);

    // If less than 4 practice trials: loop.
    if ( practice.length < min_practice ) {
      return true;

    // If last 3 not at all correct: loop.
  //  } else if ( score < 4 ) {
    //  return true;

    // Otherwise: end practice.
    } else {
      return false;
    }

  }
};

//------------------------------------//
// Define comprehension check.
//------------------------------------//
//------------------------------------//
// Define comprehension check #1.
//------------------------------------//

var quiz_01 = {
  type: 'pit-comprehension',
  prompts: [
    "Which key will you use if you want to attend to a robot?",
  ],
  options: [
     ["SPACE", "UP", "ENTER"],
  ],
  correct: [
    "SPACE",
  ],
    audio:['./static/audio/PIT_Q1.mp3'],

  view_duration: [4000],

  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_1_counter = 0;
console.log(quiz_1_counter)


var quiz_01_feedback = {
  type: 'pit-instructions',
  
  //pages: [
    //{
      pages:  function(data) {
        var Q1 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(Q1)
          if(Q1 == 0){
              return ["<b>Correct!</b>"];
          } else {
              return  ["<b>Incorrect.</b> You should press the <b>SPACE</b> bar."];
          }},//}
          //],
              robot_runes: [
    ''
  ],
  scanner_colors: [
    '#FFFFFF00'
],

 audio:['./static/audio/1-second-of-silence.mp3'],
   view_duration: [2000],


 
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',
          


   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q1 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(Q1)
    if (Q1 == 0) {
      quiz_1_counter = 0;
    } else {
      quiz_1_counter++;
    }
    console.log(quiz_1_counter)
       
   }    
};

    



const quiz_01_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_1_counter)

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
  type: 'pit-comprehension',
  prompts: [
    "When the scanner light is <b>BLUE</b>, how many points will you usually earn for a correct action?",
  ],
  options: [
     ["10","-10", "0", "5"],
  ],
  correct: [
    "10",
  ],

 audio:['./static/audio/PIT_Q2.mp3'],

  view_duration: [4000],
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_2_counter = 0;

var quiz_02_feedback = {
  type: 'pit-instructions',
  
  //pages: [
    //{
      pages:  function(data) {
        var Q2 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(Q2)
          if(Q2 == 0){
              return ["<b>Correct!</b>"];
          } else {
              return  ["<b>Incorrect.</b> When the scanner light is <b>BLUE</b>, it means that the robot is a <b>Point Giver</b>, and you can  <b>get</b> 10 points."];
          }},//}
          //],
              robot_runes: [
    ''
  ],
    audio:['./static/audio/1-second-of-silence.mp3','./static/audio/1-second-of-silence.mp3'],
   view_duration: [1000,1000],
  scanner_colors: [
    '#FFFFFF00'
],

 
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',
          


   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q2 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(Q2)
    if (Q2 == 0) {
      quiz_2_counter = 0;
    } else {
      quiz_2_counter++;
    }
    console.log(quiz_2_counter)
       
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
  console.log(quiz_2_counter)

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
  type: 'pit-comprehension',
  prompts: [
    "When the scanner light is <b>RED</b>, how many points will you usually get for making a correct action?",
  ],
  options: [
     ["10","5", "0", "-10"],
  ],
  correct: [
    "0",
  ],
    audio:['./static/audio/Pit_Q3.mp3'],
   view_duration: [6000],
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_3_counter = 0;

var quiz_03_feedback = {
  type: 'pit-instructions',
  
 // pages: [
   // {
      pages:  function(data) {
        var Q3 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(Q3)
          if(Q3 == 0){
              return ["<b>Correct!</b>"];
          } else {
              return  ["<b>Incorrect.</b> When the scanner light is <b>RED</b>, it means that the robot is a <b>Point Taker</b>, and you might lose 10 points, but if you <b>take the correct action you will get 0 points.</b>"];
          }},//}
          //],
          
                        robot_runes: [
    ''
  ],
  
      audio:['./static/audio/1-second-of-silence.mp3','./static/audio/1-second-of-silence.mp3'],
   view_duration: [1000,1000],
  
  scanner_colors: [
    '#FFFFFF00'
],

    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q3 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(Q3)
    if (Q3 == 0) {
      quiz_3_counter = 0;
    } else {
      quiz_3_counter++;
    }
    console.log(quiz_3_counter)
       
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
  console.log(quiz_3_counter)

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
  type: 'pit-comprehension',
  prompts: [
    `<i>True</i> or <i>False</i>: Some <b> <font color=${outcome_color_win}>Point Givers </font></b>  will give you points if you attend to them, others will give you points if you ignore them.`,
  ],
  options: [
     ["True", "False"],
  ],
  correct: [
    "True",
  ],
  
  audio:['./static/audio/PIT_Q4.mp3'],

  view_duration: [8000],
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_4_counter = 0;

var quiz_04_feedback = {
  type: 'pit-instructions',
  
  //pages: [
    //{
      pages:  function(data) {
        var Q4 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(Q4)
          if(Q4 == 0){
              return ["<b>Correct!</b>"];
          } else {
              return  ["<b>Incorrect.</b> Some Point Givers will give you points if you attend to them, other Point Givers will be better off ignored."];
          }},//}
          //],
          
                        robot_runes: [
    ''
  ],
      audio:['./static/audio/1-second-of-silence.mp3','./static/audio/1-second-of-silence.mp3'],
   view_duration: [1000,1000],
  scanner_colors: [
    '#FFFFFF00'
], 
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q4 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(Q4)
    if (Q4 == 0) {
      quiz_4_counter = 0;
    } else {
      quiz_4_counter++;
    }
    console.log(quiz_4_counter)
       
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
  console.log(quiz_4_counter)

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
  type: 'pit-comprehension',
  prompts: [
    "<i>True</i> or <i>False</i>: Sometimes, even if you take the right action, you will not get any points.",
  ],
  options: [
     ["True", "False"],
  ],
  correct: [
    "True",
  ],
  audio:['./static/audio/PIT_Q5.mp3'],

  view_duration: [7000],
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_5_counter = 0;

var quiz_05_feedback = {
  type: 'pit-instructions',
  
 // pages: [
   // {
      pages:  function(data) {
        var Q5 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(Q5)
          if(Q5 == 0){
              return ["<b>Correct!</b>"];
          } else {
              return  ["<b>Incorrect.</b> Not every time you take the correct action will you get points."];
          }},//}
          //],
          
                        robot_runes: [
    ''
  ],
  
      audio:['./static/audio/1-second-of-silence.mp3','./static/audio/1-second-of-silence.mp3'],
   view_duration: [1000,1000],
  scanner_colors: [
    '#FFFFFF00'
],
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q5 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(Q5)
    if (Q5 == 0) {
      quiz_5_counter = 0;
    } else {
      quiz_5_counter++;
    }
    console.log(quiz_5_counter)
       
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
  console.log(quiz_5_counter)

    if (quiz_5_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};

//------------------------------------//
// Define comprehension check #6.
//------------------------------------//

var quiz_06 = {
  type: 'pit-comprehension',
  prompts: [
    "<i>True</i> or <i>False</i>: The points I earn will affect how much bonus money I get.",
  ],
  options: [
     ["True", "False"],
  ],
  correct: [
    "True",
  ],
  audio:['./static/audio/PIT_Q6.mp3'],

  view_duration: [6000],
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_6_counter = 0;

var quiz_06_feedback = {
  type: 'pit-instructions',
  
  //pages: [
    //{
      pages:  function(data) {
        var Q6 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(Q6)
          if(Q6 == 0){
              return ["<b>Correct!</b>"];
          } else {
              return  ["<b>Incorrect.</b> The points you earn in this game will affect how much money you <b> actually </b> get at the end of the study."];
          }},//}
          //],
          
                        robot_runes: [
    ''
  ],
  
      audio:['./static/audio/1-second-of-silence.mp3','./static/audio/1-second-of-silence.mp3'],
   view_duration: [1000,1000],
  scanner_colors: [
    '#FFFFFF00'
],
          
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q6 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(Q6)
    if (Q6 == 0) {
      quiz_6_counter = 0;
    } else {
      quiz_6_counter++;
    }
    console.log(quiz_6_counter)
       
   }    
};
    


const quiz_06_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_6_counter)

        if (quiz_6_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const quiz_block_06 = {
  timeline: [
     quiz_06, quiz_06_feedback, quiz_06_help_node 
  ],
  loop_function: function(data) {
  console.log(quiz_6_counter)

    if (quiz_6_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};



//------------------------------------//
// Define comprehension check #7.
//------------------------------------//

var quiz_07 = {
  type: 'pit-comprehension',
  prompts: [
    `<i>True</i> or <i>False</i>: All <b><font color=${outcome_color_lose}>Point Takers </font></b> are better off ignored.`, 
  ],
  options: [
     ["True", "False"],
  ],
  correct: [
    "False",
  ],
  audio:['./static/audio/PIT_Q7.mp3'],

  view_duration: [4000],
  on_finish: function() {jsPsych.data.displayData();}
};


var quiz_7_counter = 0;

var quiz_07_feedback = {
  type: 'pit-instructions',
  
  //pages: [
    //{
      pages:  function(data) {
        var Q7 = jsPsych.data.get().last(1).values()[0].num_errors;
          console.log(Q7)
          if(Q7 == 0){
              return ["<b>Correct!</b>"];
          } else {
              return  ["<b>Incorrect.</b> Whether you should attend or ignore a robot is determined by its <b>TYPE</b>. The type is indicated by the <b>SYMBOL</b>. Not by the color of the scanner light."];
          }},//}
          //],
          
                        robot_runes: [
    ''
  ],
      audio:['./static/audio/1-second-of-silence.mp3','./static/audio/1-second-of-silence.mp3'],
   view_duration: [1000,1000],
   
  scanner_colors: [
    '#FFFFFF00'
],
          
          
    
  button_label_previous: 'Prev',
  button_label_next: 'Next',

   on_finish: function(data) {

    // Determine total number of practice trials.
    // Increment or reset counter.
    var Q7 = jsPsych.data.get().last(2).values()[0].num_errors;
    console.log(Q7)
    if (Q7 == 0) {
      quiz_7_counter = 0;
    } else {
      quiz_7_counter++;
    }
    console.log(quiz_7_counter)
       
   }    
};
    


const quiz_07_help_node = {
    timeline: [
        quiz_help,
    ],
    conditional_function: function(data) {
    console.log(quiz_7_counter)

        if (quiz_7_counter>0 ) {
      return true;
    } else {
      return false;
    }
}};



const quiz_block_07 = {
  timeline: [
     quiz_07, quiz_07_feedback, quiz_07_help_node 
  ],
  loop_function: function(data) {
  console.log(quiz_7_counter)

    if (quiz_7_counter == 0) {
      return false;
    } else {
      return true;
    }
  }
};


//var quiz = {
  //type: 'pit-comprehension',
  //prompts: [
    //"To <b>repair</b> a robot, what button you should press?",
    //`When the scanner light is <b><font color=${outcome_color_win}>${instr_color_win}</font></b>, how many points will you earn for a correct action?`,
    //`When the scanner light is <b><font color=${outcome_color_lose}>${instr_color_lose}</font></b>, how many points will you lose for a incorrect action?`,
    //"<i>True</i> or <i>False</i>: Some types robots will need repairs more often than other types of robots.",
    //"<i>True</i> or <i>False</i>: Sometimes, even if you take the right action you will not get all the points",
    //"<i>True</i> or <i>False</i>: The points I earn will affect my performance bonus."
  //],
  //options: [
//    ["SPACE", "Do nothing", "ENTER"],
 //   ["10", "0", "5"],
 //   ["5", "0", "10"],
 //   ["True", "False"],
  //  ["True", "False"],
  //  ["True", "False"],
  //],
 // correct: [
 //   "SPACE",
 //   "10",
 //   "10",
 //   "True",
 //   "True",
 //   "True"
 // ]
//};


// old quiz:
//var quiz = {
//  type: 'pit-comprehension',
//  prompts: [
//    "To <b>repair</b> a robot, what do you do?",
//    `When the scanner light is <b><font color=${outcome_color_win}>${instr_color_win}</font></b>, how many points will you earn for a correct action?`,
//    `When the scanner light is <b><font color=${outcome_color_lose}>${instr_color_lose}</font></b>, how many points will you avoid losing for a correct action?`,
//    "<i>True</i> or <i>False</i>: Some types robots will need repairs more often than other types of robots.",
//    "<i>True</i> or <i>False</i>: Each time you make the correct action you will get all the points.",
//    "<i>True</i> or <i>False</i>: The points I earn will affect my performance bonus."
//  ],
//  options: [
//    ["Press SPACE", "Do nothing", "Press ENTER"],
//    ["+10", "0", "-10"],
//    ["-1", "0", "-10"],
//    ["True", "False"],
//    ["True", "False, somtimes you will not get all the points even if you took the right action"],
//    ["True", "False"],
//  ],
//  correct: [
//    "Press SPACE",
//    "+10",
//    "-10",
//    "True",
//    "True"
//  ]
//}

//var error_num = jsPsych.data.get().filter({quiz: 1}).count();

// version check
console.log('boop');

//const instructions_1_help_node = {
  //timeline: [{
    //type: 'pit-instructions',
    //pages: [
     // "<p>You did not answer all of the quiz questions correctly.</p><p>Please review the instructions again, read them carefully.</p>"
    //],
//    show_clickable_nav: true,
  //  allow_backward: true
 // }],
//conditional_function: function() {
 // let error_num = jsPsych.data.getLastTrialData().select('num_errors').values[0];
 // console.log('errors: ',error_num);
  //  if (error_num > 0) {
//      return true;
  //  } else {
    //  return false;
//    }
 // }
//};


//var instructions_loop = {
//  timeline: [
    //instructions_1_help_node,
    //instructions_01,
    //instructions_02,
    //instructions_03,
    //instructions_04,
  //  instructions_05,
//    quiz
  //],
  //loop_function: function(data) {

    // Extract number of errors.
    //const num_errors = data.values().slice(-1)[0].num_errors;

    // Check if instructions should repeat.
    //n_loops++;
    //if (num_errors > max_errors && n_loops >= max_loops) {
      //return false;
    //} else if (num_errors > max_errors) {
      //return true;
    //} else {
     // return false;
    //}

  //}
//};



//------------------------------------//
// Define instructions block.
//------------------------------------//
//var INSTRUCTIONS;
//if (age=='999'){
  //INSTRUCTIONS = {
  //timeline: [
   //quiz_block_01,
    //quiz_block_02,
    //quiz_block_03,
    //quiz_block_04,
    //quiz_block_05,
    //quiz_block_06
  //]};


//} else {
  INSTRUCTIONS = {
  timeline: [
    instructions_audio,
    audio_block_01,
    audio_block_02,
 instructions_01_1,
  practice_00,
  instructions_01_2,
  practice_001,
  instructions_01_3,
  practice_01,
  attention_check,
  instructions_02,
  practice_02,
  attention_check,
  instructions_03,
  practice_03,
  attention_check,
  instructions_04,
  practice_04,
  attention_check,
  instructions_05,
 quiz_block_01,
  quiz_block_02,
  quiz_block_03,
  quiz_block_04,
  quiz_block_05,
  quiz_block_06,
  quiz_block_07  
  ]
};
//};
