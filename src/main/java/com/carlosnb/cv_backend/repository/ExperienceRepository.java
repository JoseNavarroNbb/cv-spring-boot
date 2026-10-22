package com.carlosnb.cv_backend.repository;

import com.carlosnb.cv_backend.entity.Experience;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExperienceRepository extends JpaRepository<Experience, Long> {
    // operaciones CRUD completas sin escribir una sola línea de SQL.
}