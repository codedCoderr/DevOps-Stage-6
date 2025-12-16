<template>
  <div class="dashboard-page">
    <div class="hng-brand">HNG.TECH</div>
    <app-nav></app-nav>
    <div class="container">
      <spinner v-show="isProcessing" message="Processing..."></spinner>
      <div class="dashboard-header">
        <div class="row align-items-center">
          <div class="col-sm-12">
            <h1 class="dashboard-title">
              Welcome to HNG13 TODOs Dashboard
              <transition name="fade">
                <small v-if="total" class="task-count">({{ total }})</small>
              </transition>
            </h1>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="col-sm-12">
          <div class="error-message">
            <span class="text-danger">
              {{ errorMessage }}
            </span>
          </div>
        </div>
      </div>

      <div class="task-input-container">
        <div class="row">
          <div class="col-sm-10">
            <input
              type="text"
              class="form-control task-input"
              v-model="newTask"
              @keyup.enter="addTask"
              placeholder="Add New Task"
            />
          </div>
          <div class="col-sm-2 text-right">
            <button
              type="submit"
              class="btn btn-primary add-task-btn"
              @click="addTask"
            >
              <i class="fa fa-plus"></i> Add Task
            </button>
          </div>
        </div>
      </div>

      <div class="tasks-container">
        <transition-group name="fade" tag="ul" class="no-bullet list-group">
          <todo-item
            v-for="(todo, index) in tasks"
            @remove="removeTask(index)"
            :todo="todo"
            :key="index"
            class="task-item"
          ></todo-item>
        </transition-group>
      </div>
    </div>
  </div>
</template>

<script>
import AppNav from "@/components/AppNav";
import TodoItem from "@/components/TodoItem";
import Spinner from "@/components/common/Spinner";

export default {
  name: "todos",
  components: { AppNav, TodoItem, Spinner },
  props: {
    tasks: {
      default: function () {
        return [];
      },
    },
  },
  data() {
    return {
      isProcessing: false,
      errorMessage: "",
      newTask: "",
    };
  },
  created() {
    this.loadTasks();
  },
  computed: {
    total() {
      return this.tasks.length;
    },
  },
  methods: {
    loadTasks() {
      this.isProcessing = true;
      this.errorMessage = "";
      this.$http.get(`${process.env.VUE_APP_TODOS_API_ADDRESS}/todos`).then(
        (response) => {
          for (var i in response.body) {
            this.tasks.push(response.body[i]);
          }
          this.isProcessing = false;
        },
        (error) => {
          this.isProcessing = false;
          this.errorMessage =
            JSON.stringify(error.body) + ". Response code: " + error.status;
        }
      );
    },
    addTask() {
      if (this.newTask) {
        this.isProcessing = true;
        this.errorMessage = "";
        var task = {
          content: this.newTask,
        };
        this.$http
          .post(`${process.env.VUE_APP_TODOS_API_ADDRESS}/todos`, task)
          .then(
            (response) => {
              this.newTask = "";
              this.isProcessing = false;
              this.tasks.push(task);
            },
            (error) => {
              this.isProcessing = false;
              this.errorMessage =
                JSON.stringify(error.body) + ". Response code: " + error.status;
            }
          );
      }
    },
    removeTask(index) {
      const item = this.tasks[index];
      this.isProcessing = true;
      this.errorMessage = "";
      this.$http
        .delete(`${process.env.VUE_APP_TODOS_API_ADDRESS}/todos/${item.id}`)
        .then(
          (response) => {
            this.isProcessing = false;
            this.tasks.splice(index, 1);
          },
          (error) => {
            this.isProcessing = false;
            this.errorMessage =
              JSON.stringify(error.body) + ". Response code: " + error.status;
          }
        );
    },
  },
};
</script>

<style scoped>
.dashboard-page {
  min-height: 100vh;
  background: #f8f9fa;
  padding: 20px;
  position: relative;
}

.hng-brand {
  position: fixed;
  top: 20px;
  right: 30px;
  color: #0056b3;
  font-weight: bold;
  font-size: 24px;
  z-index: 1000;
}

.container {
  margin-top: 30px;
}

.dashboard-header {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  margin-bottom: 20px;
}

.dashboard-title {
  color: #0056b3;
  font-size: 2rem;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 10px;
}

.task-count {
  color: #6c757d;
  font-size: 1.2rem;
}

.error-message {
  margin: 10px 0;
  padding: 10px;
  border-radius: 5px;
}

.task-input-container {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  margin-bottom: 20px;
}

.task-input {
  height: 50px;
  border: 2px solid #e9ecef;
  border-radius: 8px;
  padding: 0 20px;
  font-size: 1rem;
  transition: all 0.3s ease;
}

.task-input:focus {
  border-color: #0056b3;
  box-shadow: 0 0 0 0.2rem rgba(0, 86, 179, 0.25);
}

.add-task-btn {
  height: 50px;
  background-color: #0056b3;
  border: none;
  width: 100%;
  font-weight: 500;
  transition: all 0.3s ease;
}

.add-task-btn:hover {
  background-color: #003d80;
  transform: translateY(-2px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.add-task-btn:active {
  transform: translateY(0);
}

.tasks-container {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.no-bullet {
  list-style: none;
  padding: 0;
  margin: 0;
}

.task-item {
  margin-bottom: 10px;
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}
</style>
