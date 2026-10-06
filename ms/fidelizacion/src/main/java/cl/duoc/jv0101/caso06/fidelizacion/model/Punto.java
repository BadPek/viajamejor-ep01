package cl.duoc.jv0101.caso06.fidelizacion.model;

import jakarta.persistence.CascadeType;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToMany;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;


@Entity
@Table(name = "puntos")
public class Punto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String nombre;

    @Column
    private String viajero;
    @Column
    private BigDecimal puntos;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getViajero() { return viajero; }

    public void setViajero(String viajero) { this.viajero = viajero; }

    public BigDecimal getPuntos() { return puntos; }

    public void setPuntos(BigDecimal puntos) { this.puntos = puntos; }


    @OneToMany(mappedBy = "punto", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<MovimientoPunto> movimientos = new ArrayList<>();

    public List<MovimientoPunto> getMovimientos() {
        return movimientos;
    }

    public void setMovimientos(List<MovimientoPunto> movimientos) {
        if (movimientos == null) {
            return;
        }
        this.movimientos = movimientos;
        movimientos.forEach(item -> item.setPunto(this));
    }

    public void addMovimientoPunto(MovimientoPunto item) {
        item.setPunto(this);
        this.movimientos.add(item);
    }

    public void replaceMovimientos(List<MovimientoPunto> nuevos) {
        this.movimientos.clear();
        if (nuevos != null) {
            nuevos.forEach(item -> addMovimientoPunto(item));
        }
    }

}
