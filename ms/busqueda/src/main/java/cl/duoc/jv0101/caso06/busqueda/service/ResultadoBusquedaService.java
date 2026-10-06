package cl.duoc.jv0101.caso06.busqueda.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso06.busqueda.model.ResultadoBusqueda;
import cl.duoc.jv0101.caso06.busqueda.repository.ResultadoBusquedaRepository;

@Service
public class ResultadoBusquedaService {

    private final ResultadoBusquedaRepository repository;

    public ResultadoBusquedaService(ResultadoBusquedaRepository repository) {
        this.repository = repository;
    }

    public List<ResultadoBusqueda> findAll() {
        return repository.findAll();
    }

    public Optional<ResultadoBusqueda> findById(Long id) {
        return repository.findById(id);
    }

    public ResultadoBusqueda create(ResultadoBusqueda recurso) {
        return repository.save(recurso);
    }

    public Optional<ResultadoBusqueda> update(Long id, ResultadoBusqueda datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setProveedor(datos.getProveedor());
            existente.setPrecio(datos.getPrecio());
            existente.replaceFiltros(datos.getFiltros());
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
