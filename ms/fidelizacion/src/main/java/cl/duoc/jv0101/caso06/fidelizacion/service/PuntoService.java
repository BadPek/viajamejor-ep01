package cl.duoc.jv0101.caso06.fidelizacion.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso06.fidelizacion.model.Punto;
import cl.duoc.jv0101.caso06.fidelizacion.repository.PuntoRepository;

@Service
public class PuntoService {

    private final PuntoRepository repository;

    public PuntoService(PuntoRepository repository) {
        this.repository = repository;
    }

    public List<Punto> findAll() {
        return repository.findAll();
    }

    public Optional<Punto> findById(Long id) {
        return repository.findById(id);
    }

    public Punto create(Punto recurso) {
        return repository.save(recurso);
    }

    public Optional<Punto> update(Long id, Punto datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setViajero(datos.getViajero());
            existente.setPuntos(datos.getPuntos());
            existente.replaceMovimientos(datos.getMovimientos());
            return repository.save(existente);
        });
    }

    public boolean delete(Long id) {
        return repository.findById(id).map(existente -> {
            repository.delete(existente);
            return true;
        }).orElse(false);
    }
}
