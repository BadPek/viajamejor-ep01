package cl.duoc.jv0101.caso06.usuarios.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import cl.duoc.jv0101.caso06.usuarios.model.Usuario;
import cl.duoc.jv0101.caso06.usuarios.repository.UsuarioRepository;

@Service
public class UsuarioService {

    private final UsuarioRepository repository;

    public UsuarioService(UsuarioRepository repository) {
        this.repository = repository;
    }

    public List<Usuario> findAll() {
        return repository.findAll();
    }

    public Optional<Usuario> findById(Long id) {
        return repository.findById(id);
    }

    public Usuario create(Usuario recurso) {
        return repository.save(recurso);
    }

    public Optional<Usuario> update(Long id, Usuario datos) {
        return repository.findById(id).map(existente -> {
            existente.setNombre(datos.getNombre());
            existente.setEmail(datos.getEmail());
            existente.setNivel(datos.getNivel());
            existente.replaceDirecciones(datos.getDirecciones());
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
