module NotifyNewPublicTodosSubscription = %graphql(`
  subscription notifyNewPublicTodos {
    todos(
      where: { is_public: { _eq: true } }
      limit: 1
      order_by: [{ created_at: desc }]
    ) {
      id
      created_at
    }
  }
`)

module TodoPublicListContainer = {
  @react.component
  let make = (~latestTodo: NotifyNewPublicTodosSubscription.t_todos) => {
    let todosResult = PublicTodosQuery.use()
    switch todosResult {
    | {loading: true} => <div> {React.string("Loading...")} </div>
    | {data: Some({todos}), error: None} => {
        let todoList = Js.Array2.mapi(todos, (todo, index) =>
          <TaskItem key={Js.Int.toString(index)} todo={todo} />
        )

        <div className="todoListWrapper"> <ul> {React.array(todoList)} </ul> </div>
      }
    | {error} => {
        Js.log(error)
        <div> {React.string("Error!")} </div>
      }
    }
  }
}

@react.component
let make = () => {
  let newTodoSubscriptionResult = NotifyNewPublicTodosSubscription.use()
  switch newTodoSubscriptionResult {
  | {loading: true} => <div> {React.string("Loading...")} </div>
  | {data: Some({todos})} => {
      Js.log(todos)
      <TodoPublicListContainer latestTodo={todos[0]} />
    }
  | {error: Some(_error)} => <div> {React.string("Error!")} </div>
  | {data: None, error: None, loading: false} => React.null
  }
}
