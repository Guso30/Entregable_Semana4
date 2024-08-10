defmodule Survey do
  @moduledoc """
  Módulo que representa un sistema de encuestas que maneja preguntas y respuestas.
  """

  @doc """
  Inicia el proceso de encuesta.
  """
  def start do
    spawn(fn -> loop(%{}) end)
  end

  @doc """
  Añade una nueva pregunta a la encuesta.

  ## Parámetros
  - `survey_pid`: PID del proceso de encuesta.
  - `question`: Pregunta a añadir.
  """
  def add_question(survey_pid, question) do
    send(survey_pid, {:add_question, question})
  end

  @doc """
  Envía una respuesta a una pregunta de la encuesta.

  ## Parámetros
  - `survey_pid`: PID del proceso de encuesta.
  - `question`: Pregunta a la que se responde.
  - `response`: Respuesta a enviar.
  """
  def respond(survey_pid, question, response) do
    send(survey_pid, {:respond, question, response})
  end

  @doc """
  Solicita los resultados de la encuesta.

  ## Parámetros
  - `survey_pid`: PID del proceso de encuesta.

  ## Retorno
  - Devuelve un mapa con las preguntas y sus respuestas.
  """
  def results(survey_pid) do
    send(survey_pid, {:results, self()})

    receive do
      {:response, results} -> results
    end
  end

  @doc false
  defp loop(survey) do
    {new_survey, responses} =
      receive do
        {:add_question, question} ->
          IO.puts("Pregunta añadida: #{question}")
          {Map.put(survey, question, []), responses}

        {:respond, question, response} ->
          updated_survey =
            Map.update(survey, question, [response], fn responses ->
              [response | responses]
            end)

          {updated_survey, [{question, response} | responses]}

        {:results, caller_pid} ->
          send(caller_pid, {:response, survey})
          {survey, responses}

        _ ->
          IO.puts("Mensaje inválido")
          {survey, responses}
      end

    loop(new_survey)
  end
end

defmodule SurveyParticipant do
  @moduledoc """
  Módulo que representa a un participante en la encuesta.
  """

  @doc """
  Inicia un proceso de participante de encuesta.

  ## Parámetros
  - `name`: Nombre del participante.
  - `survey_pid`: PID del proceso de encuesta.
  """
  def start(name, survey_pid) do
    spawn(fn -> loop(name, survey_pid) end)
  end

  @doc false
  defp loop(name, survey_pid) do
    receive do
      {:new_question, question} ->
        IO.puts("#{name} ha visto la nueva pregunta: #{question}")
        loop(name, survey_pid)

      {:respond_to_question, question, response} ->
        Survey.respond(survey_pid, question, response)
        IO.puts("#{name} ha respondido: #{response} a #{question}")
        loop(name, survey_pid)

      {:view_results} ->
        results = Survey.results(survey_pid)
        IO.inspect(results, label: "Resultados de la encuesta")
        loop(name, survey_pid)

      _ ->
        IO.puts("Mensaje inválido")
        loop(name, survey_pid)
    end
  end
end

# Ejemplo de uso
# survey_pid = Survey.start()

# Survey.add_question(survey_pid, "¿Dónde naciste?")
# Survey.add_question(survey_pid, "¿Cuántos años tienes?")

# participant1 = SurveyParticipant.start("Gustavo", survey_pid)
# participant2 = SurveyParticipant.start("Camila", survey_pid)

# send(participant1, {:respond_to_question, "¿Dónde naciste?", "Yopal"})
# send(participant2, {:respond_to_question, "¿Cuántos años tienes?", "27"})

# send(participant1, {:view_results})
