# language: es
Característica: Servicio Integraciones (microservicio integraciones del caso caso06)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Integraciones" está disponible
    Cuando consulto el listado de "integraciones"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "integracion" con nombre "hola-cucumber"
    Cuando consulto el "integracion" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "integracion" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "integracion"
    Entonces la eliminación responde con código 204
    Y al consultar el "integracion" eliminado responde 404
