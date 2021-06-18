type todos = array<TaskItem.todo>

type state = {
  .
  "todos": array(todoType),
  "loading": bool,
};

type todosGqlResp = { 
  .
  "data": state
};

type response = {. "data": state};

external toApolloResult : 'a => response = "%identity";

module NotifyNewPublicTodosSubscription = %graphql(`
  subscription notifyNewPublicTodos {
    todos(
      where: { is_public: { _eq: true } }
      limit: 1
      order_by: [{ created_at: desc }]
    ) {
      id
      title
      created_at
      is_completed
      user {
        name
      }
    }
  }
`)

module NewTodosQuery = %graphql(`
  query ($latestVisibleId: Int) {
    todos(
      where: { is_public: { _eq: true }, id: { _gt: $latestVisibleId } }
      order_by: [{ created_at: desc }]
    ) {
      id
      title
      created_at
      user {
        name
      }
    }
  }
`)

module TodoPublicListContainer = {
  @react.component
  let make = (~latestTodo: NotifyNewPublicTodosSubscription.t_todos) => {
    let (todos: todos, setTodos) = React.useState(() => [])
    let client = ApolloClient.React.useApolloClient()
    // let todosResult = PublicTodosQuery.use({oldestTodoId: None})

    let loadOlder = _ => {
      let oldestTodoId = if Js.Array2.length(todos) > 0 {
        Js.Option.some(todos[Js.Array2.length(todos) - 1].id)
      } else {
        None
      }
      client.query(~query=module(PublicTodosQuery), {oldestTodoId: oldestTodoId})
      ->Promise.map(result =>
        switch result {
        | Ok({data: {todos}}) =>
          setTodos(previousTodos => {
            let newTodos = Js.Array2.map(todos => {id: todo.id, title: todo.title})
            Js.Array2.concat(previousTodos, )
          }
        | Error(error) => Js.log2("Error: ", error)
        }
      )
      ->ignore
    }

    React.useEffect0(() => {
      loadOlder()
      None
    })

    let todoList = Js.Array2.mapi(todos, (todo, index) =>
      <TaskItem key={Js.Int.toString(index)} todo={todo} />
    )

    <div className="todoListWrapper">
      <ul> {React.array(todoList)} </ul>
      <div className={"loadMoreSection"} onClick={loadOlder}>
        {"Load older tasks"->React.string}
      </div>
    </div>

    //   switch todosResult {
    //   | {loading: true} => <div> {React.string("Loading...")} </div>
    //   | {data: Some({todos}), error: None, fetchMore} => {
    //       let loadOlder = _e => {
    //         let oldTodo = todos[Js.Array2.length(todos) - 1]
    //         let oldTodoId = Js.Option.some(oldTodo.id)

    //         fetchMore(~updateQuery=(previousData, {fetchMoreResult}) => {
    //           switch fetchMoreResult {
    //           | Some({todos: newTodos}) => {
    //               todos: Belt.Array.concat(todos, newTodos),
    //             }
    //           | None => previousData
    //           }
    //         }, ~variables={oldestTodoId: oldTodoId}, ())
    //         // ->Promise.map(result => {
    //         //   switch result {
    //         //   | Ok(_) => Js.log("fetchMore: success!")
    //         //   | Error(_) => Js.log("fetchMore: failure!")
    //         //   }
    //         // })
    //         ->ignore
    //       }

    //       let todoList = Js.Array2.mapi(todos, (todo, index) =>
    //         <TaskItem key={Js.Int.toString(index)} todo={todo} />
    //       )

    //       <div className="todoListWrapper">
    //         <ul> {React.array(todoList)} </ul>
    //         <div className={"loadMoreSection"} onClick={loadOlder}>
    //           {"Load older tasks"->React.string}
    //         </div>
    //       </div>
    //     }
    //   | {error} => {
    //       Js.log(error)
    //       <div> {React.string("Error!")} </div>
    //     }
    //   }
  }
}

@react.component
let make = () => {
  let newTodoSubscriptionResult = NotifyNewPublicTodosSubscription.use()
  Js.log2(newTodoSubscriptionResult, "sub")
  switch newTodoSubscriptionResult {
  | {loading: true} => <div> {React.string("Loading...")} </div>
  | {data: Some({todos})} => <TodoPublicListContainer latestTodo={todos[0]} />
  | {error: Some(_error)} => <div> {React.string("Error!")} </div>
  | {data: None, error: None, loading: false} => React.null
  }
}
