package com.carlosnb.cv_backend.service;

import com.carlosnb.cv_backend.entity.Experience;
import com.carlosnb.cv_backend.repository.ExperienceRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ExperienceService {

    private final ExperienceRepository experienceRepository;

    public ExperienceService(ExperienceRepository experienceRepository) {
        this.experienceRepository = experienceRepository;
    }

    public List<Experience> getAllExperiences() {
        return experienceRepository.findAll();
    }

    // Cambiado de Long a Integer
    public Optional<Experience> getExperienceById(Integer id) {
        return experienceRepository.findById(id);
    }

    public Experience saveExperience(Experience experience) {
        return experienceRepository.save(experience);
    }

    // Cambiado de Long a Integer
    public void deleteExperience(Integer id) {
        experienceRepository.deleteById(id);
    }
}