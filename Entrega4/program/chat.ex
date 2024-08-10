defmodule ChatServer do
  @moduledoc """
  Módulo que representa un servidor de chat que maneja múltiples usuarios y mensajes.
  """

  @doc """
  Inicia el servidor de chat.
  """
  def start do
    spawn(fn -> loop(%{}) end)
  end

  @doc """
  Permite que un usuario se una al servidor de chat.

  ## Parámetros
  - `server_pid`: PID del proceso del servidor de chat.
  - `user_name`: Nombre del usuario que se va a unir.
  """
  def join(server_pid, user_name) do
    send(server_pid, {:join, user_name, self()})
  end

  @doc """
  Envía un mensaje a todos los usuarios conectados.

  ## Parámetros
  - `server_pid`: PID del proceso del servidor de chat.
  - `user_name`: Nombre del usuario que envía el mensaje.
  - `message`: Mensaje a enviar.
  """
  def send_message(server_pid, user_name, message) do
    send(server_pid, {:message, user_name, message})
  end

  @doc """
  Solicita la lista de usuarios conectados.

  ## Parámetros
  - `server_pid`: PID del proceso del servidor.

  ## Retorno
  - Devuelve la lista de usuarios conectados.
  """
  def list_users(server_pid) do
    send(server_pid, {:list_users, self()})

    receive do
      {:response, users} -> users
    end
  end

  @doc false
  defp loop(users) do
    {new_users, messages} =
      receive do
        {:join, user_name, user_pid} ->
          send(user_pid, {:joined, user_name})
          {Map.put(users, user_name, user_pid), []}

        {:message, user_name, message} ->
          IO.puts("#{user_name}: #{message}")
          {users, [{user_name, message}]}

        {:list_users, caller_pid} ->
          send(caller_pid, {:response, Map.keys(users)})
          {users, []}

        _ ->
          IO.puts("Invalid Message")
          {users, []}
      end

    loop(new_users)
  end
end

defmodule ChatUser do
  @moduledoc """
  Módulo que representa a un usuario en el chat.
  """

  @doc """
  Inicia un proceso de usuario de chat.

  ## Parámetros
  - `name`: Nombre del usuario.
  - `server_pid`: PID del proceso del servidor de chat.
  """
  def start(name, server_pid) do
    spawn(fn -> loop(name, server_pid) end)
  end

  @doc false
  defp loop(name, server_pid) do
    receive do
      {:joined, user_name} ->
        IO.puts("#{user_name} se ha unido al chat!")
        loop(name, server_pid)

      {:message, message} ->
        IO.puts("#{name}: #{message}")
        loop(name, server_pid)

      {:send_message, message} ->
        ChatServer.send_message(server_pid, name, message)
        loop(name, server_pid)

      {:list_users} ->
        users = ChatServer.list_users(server_pid)
        IO.inspect(users, label: "Usuarios conectados")
        loop(name, server_pid)

      _ ->
        IO.puts("Mensaje inválido")
        loop(name, server_pid)
    end
  end
end

# Ejemplo de uso
# chat_server_pid = ChatServer.start()
# user1 = ChatUser.start("Gustavo", chat_server_pid)
# user2 = ChatUser.start("Camila", chat_server_pid)

# ChatServer.join(chat_server_pid, "Gustavo")
# ChatServer.join(chat_server_pid, "Camila")

# send(user1, {:send_message, "Hola a todos!"})
# send(user2, {:send_message, "Hola Gustavo!"})

# send(user1, {:list_users})
