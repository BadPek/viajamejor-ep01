package cl.duoc.jv0101.caso06.reservas.model;

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


@Entity
@Table(name = "reservas")
public class Reserva {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String nombre;

    @Column
    private String proveedor;
    @Column
    private String fecha;

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

    public String getProveedor() { return proveedor; }

    public void setProveedor(String proveedor) { this.proveedor = proveedor; }

    public String getFecha() { return fecha; }

    public void setFecha(String fecha) { this.fecha = fecha; }


    @OneToMany(mappedBy = "reserva", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<ItemReserva> items = new ArrayList<>();

    public List<ItemReserva> getItems() {
        return items;
    }

    public void setItems(List<ItemReserva> items) {
        if (items == null) {
            return;
        }
        this.items = items;
        items.forEach(item -> item.setReserva(this));
    }

    public void addItemReserva(ItemReserva item) {
        item.setReserva(this);
        this.items.add(item);
    }

    public void replaceItems(List<ItemReserva> nuevos) {
        this.items.clear();
        if (nuevos != null) {
            nuevos.forEach(item -> addItemReserva(item));
        }
    }

}
