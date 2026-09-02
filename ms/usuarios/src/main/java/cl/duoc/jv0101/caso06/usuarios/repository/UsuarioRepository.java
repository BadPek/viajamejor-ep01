package cl.duoc.jv0101.caso06.usuarios.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso06.usuarios.model.Usuario;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
}
