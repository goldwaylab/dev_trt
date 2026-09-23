/**
 * jspsych-pit-instructions
 * Sam Zorowitz
 *
 * plugin for running the instructions for the PIT task
 *
 **/

jsPsych.plugins["pit-instructions"] = (function() {

  var plugin = {};

  plugin.info = {
    name: 'pit-instructions',
    description: '',
    parameters: {
      pages: {
        //type: jsPsych.plugins.parameterType.HTML_STRING,
        type: jsPsych.plugins.parameterType.COMPLEX, //edit
        pretty_name: 'Pages',
        nested: {
          prompt: {
            type: jsPsych.plugins.parameterType.STRING,
            pretty_name: 'Prompt',
            default: undefined,
            description: 'Instructions text for the page.'
          },
        
        default: undefined,
        array: true,
        description: 'Each element of the array is the content for a single page.'
      },
      robot_runes: {
        type: jsPsych.plugins.parameterType.STRING,
        pretty_name: 'Robot rune',
        array: true,
        default: [''],
        description: 'Filenames of rune images in static folder. Should be same length as pages.'
      },
      scanner_colors: {
        type: jsPsych.plugins.parameterType.HTML_STRING,
        pretty_name: 'Scanner color',
        array: true,
        default: [],
        description: 'Color of scanner light. Should be same length as pages.'
      },
      key_forward: {
        type: jsPsych.plugins.parameterType.KEYCODE,
        pretty_name: 'Key forward',
        default: 'rightarrow',
        description: 'The key the subject can press in order to advance to the next page.'
      },
      key_backward: {
        type: jsPsych.plugins.parameterType.KEYCODE,
        pretty_name: 'Key backward',
        default: 'leftarrow',
        description: 'The key that the subject can press to return to the previous page.'
      },
    view_duration: {
      type: jsPsych.plugins.parameterType.INT,
      pretty_name: 'View duration',
      array: true,
      default: [0],
      description: 'How long to show instructions before next is clickable.'
          },
     audio: {
            type: jsPsych.plugins.parameterType.AUDIO,
            pretty_name: 'Audio',
            array: true,
            default: undefined,
            description: 'Audio file reading the text on the page.'
          },
     

      }//edit
    }
  };

  plugin.trial = function(display_element, trial) {

    //---------------------------------------//
    // Define HTML.
    //---------------------------------------//

    // Initialize HTML.
    var new_html = `<style>
    body {
      background: -webkit-gradient(linear, left bottom, left top, from(#808080), color-stop(50%, #606060), color-stop(50%, rgba(28, 25, 23, 0.5)), to(rgba(179, 230, 230, 0.5)));
      background: linear-gradient(0deg, #808080 0%, #606060 50%, #A0A0A0 50%, #D3D3D3 100%);
      height: 100vh;
      max-height: 100vh;
      overflow: hidden;
      position: fixed;
    }
    .jspsych-content-wrapper {
      overflow: hidden;
    }
    .conveyor:after {
      -webkit-animation: none;
      animation: none;
    }
    </style>`;

    // Add robot factor wrapper.
    new_html += '<div class="factory-wrap">';

    // Add factory machine parts (back).
    new_html += '<div class="machine-back"></div>';
    new_html += '<div class="conveyor"></div>';
    new_html += '<div class="shadows"></div>';

    // Add robot 1 (active).
    new_html += '<div class="robot">';
    new_html += '<div class="antenna"></div>';
    new_html += '<div class="head"></div>';
    new_html += '<div class="torso">';
    new_html += '<div class="left"></div>';
    new_html += '<div class="right"></div>';
    new_html += `<div class="rune" set="elianto" style="animation: none; -webkit-animation: none;"></div></div>`;
    new_html += '<div class="foot"></div></div>';

    // Add factory window.
    new_html += `<div class="scanner-light" style="animation: none; -webkit-animation: none;"></div>`;

    // Add factory machine parts (front).
    new_html += '<div class="machine-front">';
    new_html += '<div class="score-container"></div>';
    new_html += '<div class="jspsych-instructions-nav">';
    new_html += '<button id="jspsych-instructions-back" class="jspsych-btn" style="margin-right: 5px;" disabled="disabled">&lt; Prev</button>';
 //   new_html += '<button id="jspsych-instructions-next" class="jspsych-btn" disabled='true' style="margin-left: 5px;">Next &gt;</button>';
    new_html += '<button id="jspsych-instructions-next" class="jspsych-btn" disabled="true" style="margin-left: 5px;">Next &gt;</button>';

    //new_html += '<button id="jspsych-instructions-next" class="jspsych-btn" style="margin-left: 5px;">Next &gt;</button>';
    new_html += '</div></div>';
    new_html += '<div class="machine-top"></div>';

    // Draw instructions
    new_html += '<div class="instructions-box"><div class="instructions"></div></div>';

    // Close wrapper
    new_html += '</div>';

    // draw
    display_element.innerHTML = new_html;

    //---------------------------------------//
    // Task functions.
    //---------------------------------------//

    // Initialize variables.
    var current_page = 0;
    var view_history = [];
    var start_time = performance.now();
    var last_page_update_time = start_time;



    // Prepare robot runes.
    var robot_runes = [];
    for (var i=0; i<trial.pages.length; i++){
      robot_runes.push( trial.robot_runes[i] == undefined ? '' : trial.robot_runes[i] );
    }

    // Initialize scanner colors.
    var scanner_colors = [];
    for (let i=0; i<trial.pages.length; i++){
       // console.log('i_index',[i])
      scanner_colors.push( trial.scanner_colors[i] == undefined ? '#FFFFFF00' : trial.scanner_colors[i] );
    }
        
    var view_duration = [];
    for (let i=0; i<trial.pages.length; i++){
         console.log('i_index_view',[i])
        view_duration.push (trial.view_duration[i] == undefined ? '0' : trial.view_duration[i] );
        //view_duration.push('testing');
         console.log('view_duration',trial.view_duration)
     }
     
      

 var audio = [];
for (let i=0; i<trial.pages.length; i++){
    console.log('i_index', i); 
   console.log('trial.audio',trial.audio[i]);
    audio.push (trial.audio[i] == undefined ? '0' : trial.audio[i] );
    console.log('audio',trial.audio)

}

    



    // Define EventListener.
    function btnListener(evt){
    	evt.target.removeEventListener('click', btnListener);
    	if(this.id === "jspsych-instructions-back"){
    		back();
    	}
    	else if(this.id === 'jspsych-instructions-next'){
    		next();
    	}
    }

    function show_current_page() {

      // Update instructions text.
      display_element.querySelector('.instructions').innerHTML = `<p>${trial.pages[current_page]}</p>`;

      // Update robot rune.
      display_element.querySelector('.rune').innerHTML = robot_runes[current_page];

      // Update scanner color.
      display_element.querySelector('.scanner-light').style['border-bottom-color'] = scanner_colors[current_page];

      // Update prev button
      if (current_page != 0) {
        display_element.querySelector('#jspsych-instructions-back').disabled = false;
        display_element.querySelector('#jspsych-instructions-back').addEventListener('click', btnListener);
      } else {
        display_element.querySelector('#jspsych-instructions-back').disabled = true;
      }

       console.log('current_page',current_page)
            console.log('view_duration', trial.view_duration[current_page])



    
     //setTimeout(function(){ document.getElementById('jspsych-instructions-next').disabled=false}, trial.view_duration[current_page]);
            
  console.log('current_page',current_page)
    console.log('audio[current_page]', audio[current_page])
    console.log('trial.audio[current_page]', trial.audio[current_page])

  
  var context = jsPsych.pluginAPI.audioContext();
//if (current_page != 0) {
   jsPsych.pluginAPI.getAudioBuffer(trial.audio[current_page])
  //jsPsych.pluginAPI.getAudioBuffer('./static/audio/PIT_1_welcome.mp3')
  .then(function(buffer){
    audio = context.createBufferSource();
    audio.buffer = buffer;
    audio.connect(context.destination);
    audio.start(context.currentTime);
  })//}
//  .catch(function(err){
  //  console.error('Audio file failed to load')
  //})};

//var source = context.createBufferSource();
//source.buffer = jsPsych.pluginAPI.getAudioBuffer('./static/audio/PIT_1_welcome.mp3');
//source.connect(context.destination);
//startTime = context.currentTime + 0.1;
//source.start(startTime);


      // Update next button
      //display_element.querySelector('#jspsych-instructions-next').addEventListener('click', btnListener);
        console.log('current_page',current_page)
            console.log('view_duration', trial.view_duration[current_page])         
      setTimeout(function(){display_element.querySelector('#jspsych-instructions-next').addEventListener('click', btnListener);}, trial.view_duration[current_page]);
         
      setTimeout(function(){ document.getElementById('jspsych-instructions-next').disabled=false}, trial.view_duration[current_page]);


    }

    function next() {

      add_current_page_to_view_history();

      current_page++;

      // if done, finish up...
      if (current_page >= trial.pages.length) {
        endTrial();
      } else {
        show_current_page();
      }

    }

    function back() {

      add_current_page_to_view_history();

      current_page--;

      show_current_page();
    }

    function add_current_page_to_view_history() {

      var current_time = performance.now();

      var page_view_time = current_time - last_page_update_time;

      view_history.push({
        page_index: current_page,
        viewing_time: page_view_time
      });

      last_page_update_time = current_time;
    }

    function endTrial() {

      jsPsych.pluginAPI.cancelKeyboardResponse(keyboard_listener);

      display_element.innerHTML = '';

      var trial_data = {
        "view_history": JSON.stringify(view_history),
        "rt": performance.now() - start_time
      };

      jsPsych.finishTrial(trial_data);
    }

    var after_response = function(info) {

      // have to reinitialize this instead of letting it persist to prevent accidental skips of pages by holding down keys too long
      keyboard_listener = jsPsych.pluginAPI.getKeyboardResponse({
        callback_function: after_response,
        valid_responses: [trial.key_forward, trial.key_backward],
        rt_method: 'performance',
        persist: false,
        allow_held_key: false
      });
      // check if key is forwards or backwards and update page
      if (jsPsych.pluginAPI.compareKeys(info.key, trial.key_backward)) {
        if (current_page !== 0) {
          back();
        }
      }

      if (jsPsych.pluginAPI.compareKeys(info.key, trial.key_forward)) {
        next();
      }

    };

    show_current_page();

    var keyboard_listener = jsPsych.pluginAPI.getKeyboardResponse({
      callback_function: after_response,
      valid_responses: [trial.key_forward, trial.key_backward],
      rt_method: 'performance',
      persist: false
    });
  };

  return plugin;
})();
