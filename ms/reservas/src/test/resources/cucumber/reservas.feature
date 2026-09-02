# language: es
Característica: Servicio Reservas (microservicio reservas del caso caso06)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Reservas" está disponible
    Cuando consulto el listado de "reservas"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "reserva" con nombre "hola-cucumber"
    Cuando consulto el "reserva" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "reserva" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "reserva"
    Entonces la eliminación responde con código 204
    Y al consultar el "reserva" eliminado responde 404
