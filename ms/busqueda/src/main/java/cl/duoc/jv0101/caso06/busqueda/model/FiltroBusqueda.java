package cl.duoc.jv0101.caso06.busqueda.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "filtros_busqueda")
public class FiltroBusqueda {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column
    private String categoria;
    @Column
    private String valor;
    @Column
    private Boolean activo;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "resultado_id", nullable = false)
    private ResultadoBusqueda resultadoBusqueda;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCategoria() { return categoria; }
    public void setCategoria(String categoria) { this.categoria = categoria; }
    public String getValor() { return valor; }
    public void setValor(String valor) { this.valor = valor; }
    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean activo) { this.activo = activo; }

    public ResultadoBusqueda getResultadoBusqueda() { return resultadoBusqueda; }
    public void setResultadoBusqueda(ResultadoBusqueda resultadoBusqueda) { this.resultadoBusqueda = resultadoBusqueda; }
}
