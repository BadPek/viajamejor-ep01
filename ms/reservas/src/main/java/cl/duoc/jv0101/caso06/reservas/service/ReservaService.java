package cl.duoc.jv0101.caso06.reservas.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso06.reservas.model.Reserva;
import cl.duoc.jv0101.caso06.reservas.repository.ReservaRepository;

@Service
public class ReservaService {

    private final ReservaRepository repository;

    public ReservaService(ReservaRepository repository) {
        this.repository = repository;
    }

    public List<Reserva> findAll() {
        return repository.findAll();
    }

    public Optional<Reserva> findById(Long id) {
        return repository.findById(id);
    }

    public Reserva create(Reserva recurso) {
        return repository.save(recurso);
    }

    public Optional<Reserva> update(Long id, Reserva datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setProveedor(datos.getProveedor());
            existente.setFecha(datos.getFecha());
            existente.replaceItems(datos.getItems());
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
