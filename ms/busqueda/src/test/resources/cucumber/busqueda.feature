# language: es
Característica: Servicio Búsqueda (microservicio busqueda del caso caso06)
  Los escenarios validan el contrato REST del microservicio alineado a sus endpoints.

  Escenario: el listado del recurso responde 200
    Dado el servicio "Búsqueda" está disponible
    Cuando consulto el listado de "resultados"
    Entonces el listado responde con código 200

  Escenario: ciclo de vida completo del recurso
    Dado un nuevo "resultado" con nombre "hola-cucumber"
    Cuando consulto el "resultado" recién creado
    Entonces el recurso tiene nombre "hola-cucumber" y código 200
    Cuando actualizo el "resultado" con nombre "cucumber-actualizado"
    Entonces el recurso queda con nombre "cucumber-actualizado" y código 200
    Cuando elimino el "resultado"
    Entonces la eliminación responde con código 204
    Y al consultar el "resultado" eliminado responde 404
