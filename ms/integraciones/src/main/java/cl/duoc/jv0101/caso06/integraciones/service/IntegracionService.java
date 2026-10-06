package cl.duoc.jv0101.caso06.integraciones.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso06.integraciones.model.Integracion;
import cl.duoc.jv0101.caso06.integraciones.repository.IntegracionRepository;

@Service
public class IntegracionService {

    private final IntegracionRepository repository;

    public IntegracionService(IntegracionRepository repository) {
        this.repository = repository;
    }

    public List<Integracion> findAll() {
        return repository.findAll();
    }

    public Optional<Integracion> findById(Long id) {
        return repository.findById(id);
    }

    public Integracion create(Integracion recurso) {
        return repository.save(recurso);
    }

    public Optional<Integracion> update(Long id, Integracion datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setProveedor(datos.getProveedor());
            existente.setEstado(datos.getEstado());
            existente.replaceRegistros(datos.getRegistros());
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
