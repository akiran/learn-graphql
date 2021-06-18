type user = {name: string}
type todo = {
  id: int,
  title: string,
  user: user,
}

@react.component
let make = (~todo) => {
  <li>
    <div className="userInfoPublic"> {`@${todo.user.name}`->React.string} </div>
    <div className="labelContent"> <div> {todo.title->React.string} </div> </div>
  </li>
}

let default = make
