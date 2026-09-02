# language: es
Característica: Servicio Notificaciones (microservicio notificaciones del caso caso06)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Notificaciones" está disponible
    Cuando consulto el listado de "notificaciones"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "notificacion" con nombre "hola-cucumber"
    Cuando consulto el "notificacion" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "notificacion" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "notificacion"
    Entonces la eliminación responde con código 204
    Y al consultar el "notificacion" eliminado responde 404
