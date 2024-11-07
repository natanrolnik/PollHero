<script>
  import Question from './lib/Question.svelte';
  import { onMount } from 'svelte';

  // const socket = new WebSocket('wss://poll-hero-1b16db57f7aa.herokuapp.com/questions');
  // const socket = new WebSocket('ws://localhost:8080/questions');

  let question;
  let finished = false
  
  async function getQuestion() {
    try {
      const response = await fetch('https://poll-hero-server.natanrolnik.me/fallback/question');
      const json = await response.json();

      if (json.idle) {
        question = null
        finished = false
      } else if (json.finished) {
        question = null
        finished = true
      } else if (json.question) {
        if (!question || question.id != json.question.id) {
          question = json.question
        }
      }
    } catch (error) {
      console.error('Error fetching data:', error);
    }
  }

  // onMount(async () => {
  //   if (!finished) {
  //     await getQuestion()
  //     setInterval(getQuestion, 1000);
  //   }
  // });
  
  
  // Connection opened
  // socket.addEventListener('open', function (event) {
  //     console.log("Socket is open");
  // });
  //
  // Listen for messages
  // socket.addEventListener('message', function (event) {
  //     const json = JSON.parse(event.data);
  //     
  //     if (json.finished) {
  //       question = null
  //       finished = true
  //     } else if (json.question) {
  //       question = json.question
  //     }
  // });
</script>

<!-- <main> -->
  <!--{#if question != null}
  //   <Question id={ question.id } text={ question.text } answers={ question.answers } />
  // {:else}
  //   {#if finished}
  //     Thanks for participating! Back to the talk.
  //   {:else}-->
    <h2>
      😅 Talk is over 😅
    </h2>
    <!-- {/if}
  {/if} -->
  
<!-- </main> -->

<style>

</style>
