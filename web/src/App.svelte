<script>
  import Question from './lib/Question.svelte';

  const socket = new WebSocket('wss://poll-hero-1b16db57f7aa.herokuapp.com/questions');

  let question;
  let finished = false

  // Connection opened
  socket.addEventListener('open', function (event) {
      console.log("Socket is open");
  });

  // Listen for messages
  socket.addEventListener('message', function (event) {
      const json = JSON.parse(event.data);
      
      if (json.finished) {
        question = null
        finished = true
      } else if (json.question) {
        question = json.question
      }
  });
</script>

<!-- <main> -->
  {#if question != null}
    <Question id={ question.id } text={ question.text } answers={ question.answers } />
  {:else}
    {#if finished}
      Thanks for participating! Back to the talk.
    {:else}
    <h2>
      Questions will begin shortly.
    </h2>
    {/if}
  {/if}
  
<!-- </main> -->

<style>

</style>
