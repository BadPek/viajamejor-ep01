package cl.duoc.jv0101.caso06.integraciones.model;

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
@Table(name = "registros_llamada")
public class RegistroLlamada {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column
    private String endpoint;
    @Column
    private Integer codigoHttp;
    @Column
    private Long tiempoRespuestaMs;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "integracion_id", nullable = false)
    private Integracion integracion;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getEndpoint() { return endpoint; }
    public void setEndpoint(String endpoint) { this.endpoint = endpoint; }
    public Integer getCodigoHttp() { return codigoHttp; }
    public void setCodigoHttp(Integer codigoHttp) { this.codigoHttp = codigoHttp; }
    public Long getTiempoRespuestaMs() { return tiempoRespuestaMs; }
    public void setTiempoRespuestaMs(Long tiempoRespuestaMs) { this.tiempoRespuestaMs = tiempoRespuestaMs; }

    public Integracion getIntegracion() { return integracion; }
    public void setIntegracion(Integracion integracion) { this.integracion = integracion; }
}
