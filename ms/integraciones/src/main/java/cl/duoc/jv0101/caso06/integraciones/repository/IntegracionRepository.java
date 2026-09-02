package cl.duoc.jv0101.caso06.integraciones.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso06.integraciones.model.Integracion;

public interface IntegracionRepository extends JpaRepository<Integracion, Long> {
}
