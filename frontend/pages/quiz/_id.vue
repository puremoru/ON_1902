<template>
  <div class="conatainer">
    <h3 class="text-center margin-top1">今日の{{ response.ranking_theme }}ベスト{{ response.candidate_answers.length }}🔥</h3>
    <modal :val=true :description=this.successDescription :productUrl=this.productUrl v-if="isCorrect" @close="closeModal"></modal>
    <modal :val=false v-if="isFalse" @close="closeModal"></modal>
    <finishModal v-if="isFinish" @close="closeFinishModal"></finishModal>

    <div class="margin-top2 text-center container" v-if="ranking.length > 0">
      <ul class="list-group margin-top2" v-for="r in ranking" :key="r.rank">
        <li v-if="r.rank === 1" class="first-rank-list list-group-item"><b>{{ r.rank }}. {{ r.name }}</b></li>
        <li v-else-if="r.rank === 2" class="second-rank-list list-group-item"><b>{{ r.rank }}. {{ r.name }}</b></li>
        <li v-else-if="r.rank === 3" class="third-rank-list list-group-item"><b>{{ r.rank }}. {{ r.name }}</b></li>
        <li v-else class="list-group-item"><b>{{ r.rank }}. {{ r.name }}</b></li>
      </ul>
    </div>

    <div v-else>
      <div class="row margin-top2">
        <div id="1" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>1</b></div>
        <div id="2" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>2</b></div>
        <div id="3" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>3</b></div>
      </div>
      <div class="row">
        <div id="4" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>4</b></div>
        <div id="5" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>5</b></div>
        <div id="6" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>6</b></div>
      </div>
      <div class="row">
        <div id="7" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>7</b></div>
        <div id="8" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>8</b></div>
        <div id="9" class="col-4 text-center pannel" @dragover="answerQuiz($event)"><b>9</b></div>
      </div>
    </div>

    <div class="choice-group text-center">
      <button :id="answer.id" type="button" draggable=true @dragstart="dragCard(answer, $event)" @dragend="dragEnd($event)" class="btn btn-warning choice-button" v-for="answer in response.candidate_answers" :key="answer.id">{{ answer.name }}</button>
    </div>
  </div>
</template>

<script>
import modal from '~/components/modal.vue'
import finishModal from '~/components/finishModal.vue'
export default {
  async asyncData({ route, app }) {
    const response = await app.$axios.$get(`https://pannel-break-backend.herokuapp.com/api/v1/quizes/${route.params.id}`);
    // const keywords = await app.$axios.$get(`${process.env.apiBaseUrl}/api/v1/quizes/new`);
    return {
      response
    }
  },
  components: {
    modal,
    finishModal
  },
  data() {
    return {
      'draggingName': '',
      'draggingId': '',
      'onDraggingPannelId': '',
      'isCorrect': false,
      'isFalse': false,
      'isFinish': false,
      'ranking': [],
      'successDescription': '',
      'productUrl': ''
    }
  },
  methods: {
    answerQuiz(e) {
      this.onDraggingPannelId = e.target.id
      let pannels = document.getElementsByClassName("pannel");
      for(let i = 0; i < pannels.length; i++) {
        pannels[i].style.opacity = 1;
      }
      e.target.style.opacity = 0.5
    },
    dragCard(answer, e) {
      this.draggingName = answer.name
      this.draggingId = answer.id
      console.log(this.draggingName);
      e.target.style.opacity = 0.5;
    },
    async dragEnd(e) {
      if (this.draggingName && this.onDraggingPannelId) {
        const response = await this.$axios.$post(`https://pannel-break-backend.herokuapp.com/api/v1/quizes/${this.$route.params.id}/ranking/${this.onDraggingPannelId}/mark`, {
          answer: this.draggingName
        })
        console.log(response)
        if (response.is_success) {
          this.successDescription = response.description;
          this.productUrl = response.product_url;
          let answer = document.getElementById(this.draggingId);
          answer.parentNode.removeChild(answer);
          let answers = document.getElementsByClassName('choice-button');
          if (answers.length === 0) {
            this.isFinish = true;
            const response = await this.$axios.$get(`https://pannel-break-backend.herokuapp.com/api/v1/quizes/${this.$route.params.id}/ranking_list`);
            this.ranking = response.ranking
            console.log(this.ranking)
          } else {
            console.log(this.successDescription);
            this.isCorrect = true;
          }
          let pannel = document.getElementById(this.onDraggingPannelId);
          pannel.style.backgroundColor = '#FF1A6F';

        } else {
          this.isFalse = true;
        }
      }

      let pannels = document.getElementsByClassName("pannel");
      for(let i = 0; i < pannels.length; i++) {
        pannels[i].style.opacity = 1;
      }
      e.target.style.opacity = 1
      this.draggingName = ''
      this.onDraggingPannelId = ''
    },
    closeModal() {
      this.isCorrect = false;
      this.isFalse = false;
    },
    closeFinishModal() {
      this.isFinish = false;
    }
  }
}
</script>

<style>
.margin-top1 {
  margin-top: 1em;
}
.margin-top2 {
  margin-top: 2em;
}
.margin-top3 {
  margin-top: 3em;
}

.pannel {
  height: 6em;
  line-height:125px;
  border-style: solid;
  font-size: 1.5rem;
  background-color: aquamarine;
}

.finish-pannel {
  height: 6em;
  line-height:125px;
  border-style: solid;
  font-size: 1rem;
  background-color: #FF1A6F;
}

.pannel-button {
  width: 100%;
  height: 100%;
}

.choice-button {
  margin-left: 1em;
  margin-top: 2em;
  font-size: 1.3rem;
}

.first-rank-list {
  background-color: #FFD700;
}

.second-rank-list {
  background-color: #CCCCCC;
}

.third-rank-list {
  background-color: #F4A460;
}
</style>

