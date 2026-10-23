package com.carlosnb.cv_backend.repository;

import com.carlosnb.cv_backend.entity.Habilidad;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface HabilidadRepository extends JpaRepository<Habilidad, Integer> {
    // Spring Data JPA crea la consulta SQL automáticamente
    boolean existsByNombre(String nombre);
}