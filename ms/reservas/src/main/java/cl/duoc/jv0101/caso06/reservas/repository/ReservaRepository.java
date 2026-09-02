package cl.duoc.jv0101.caso06.reservas.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import cl.duoc.jv0101.caso06.reservas.model.Reserva;

public interface ReservaRepository extends JpaRepository<Reserva, Long> {
}
