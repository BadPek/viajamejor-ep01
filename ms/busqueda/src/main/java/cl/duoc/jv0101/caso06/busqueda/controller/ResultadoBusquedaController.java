package cl.duoc.jv0101.caso06.busqueda.controller;

import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import cl.duoc.jv0101.caso06.busqueda.model.ResultadoBusqueda;
import cl.duoc.jv0101.caso06.busqueda.service.ResultadoBusquedaService;

@RestController
@RequestMapping("/api/resultados")
public class ResultadoBusquedaController {

    private final ResultadoBusquedaService service;

    public ResultadoBusquedaController(ResultadoBusquedaService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<ResultadoBusqueda>> listar() {
        return ResponseEntity.ok(service.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResultadoBusqueda> obtener(@PathVariable Long id) {
        return service.findById(id).map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<ResultadoBusqueda> crear(@Valid @RequestBody ResultadoBusqueda recurso) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(recurso));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResultadoBusqueda> actualizar(@PathVariable Long id,
            @Valid @RequestBody ResultadoBusqueda datos) {
        return service.update(id, datos).map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        return service.delete(id) ? ResponseEntity.noContent().build()
                : ResponseEntity.notFound().build();
    }
}
