package cl.duoc.jv0101.caso06.notificaciones.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso06.notificaciones.model.Notificacion;

public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {
}
