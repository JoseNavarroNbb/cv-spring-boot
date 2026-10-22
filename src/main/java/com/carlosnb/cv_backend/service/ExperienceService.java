package com.carlosnb.cv_backend.service;

import com.carlosnb.cv_backend.entity.Experience;
import com.carlosnb.cv_backend.repository.ExperienceRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service // Registra esta clase en el contenedor de dependencias (IoC)
public class ExperienceService {

    private final ExperienceRepository experienceRepository;

    // Inyección de dependencias por constructor (Recomendado en Spring moderno)
    public ExperienceService(ExperienceRepository experienceRepository) {
        this.experienceRepository = experienceRepository;
    }

    public List<Experience> getAllExperiences() {
        return experienceRepository.findAll();
    }

    public Optional<Experience> getExperienceById(Long id) {
        return experienceRepository.findById(id);
    }

    public Experience saveExperience(Experience experience) {
        return experienceRepository.save(experience);
    }

    public void deleteExperience(Long id) {
        experienceRepository.deleteById(id);
    }
}