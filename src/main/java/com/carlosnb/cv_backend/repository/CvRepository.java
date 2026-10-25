package com.carlosnb.cv_backend.repository;

import com.carlosnb.cv_backend.entity.Cv;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CvRepository extends JpaRepository<Cv, Integer> {
    // Spring Data JPA crea la consulta SQL automáticamente para buscar por slug
    Cv findBySlug(String slug);
}