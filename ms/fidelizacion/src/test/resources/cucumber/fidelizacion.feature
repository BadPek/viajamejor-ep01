# language: es
Característica: Servicio Fidelización (microservicio fidelizacion del caso caso06)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Fidelización" está disponible
    Cuando consulto el listado de "puntos"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "punto" con nombre "hola-cucumber"
    Cuando consulto el "punto" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "punto" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "punto"
    Entonces la eliminación responde con código 204
    Y al consultar el "punto" eliminado responde 404
