<script>
  import { beforeUpdate, afterUpdate } from 'svelte';
    
  export let id;
  export let text;
  export let answers;
  let lastVoteId;

  async function submitVote(index) {
      if (lastVoteId === id) { return };

      lastVoteId = id;
      const res = await fetch('https://poll-hero-1b16db57f7aa.herokuapp.com/vote', {
        method: 'POST',
        body: JSON.stringify({questionId: id, index: index}),
        headers: { 'Content-Type': 'application/json' }
      })
  }
</script>

<h2>
    { text }
</h2>

<ul>
{#each answers as answer, index}
    <li>
        <button type="button" on:click={ () => submitVote(index) } disabled={ lastVoteId === id }>
            { answer }
        </button>
    </li>
{/each}
</ul>

<style>

ul {
    margin: 0;
    padding: 0;
}

li {
    list-style-type: none;
    margin: 1em;
}

</style>
