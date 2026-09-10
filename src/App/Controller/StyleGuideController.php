<?php

namespace App\Controller;

use Framework\Controller\AbstractController;
use Framework\Http\Response;
use Framework\Routing\Route;

/**
 * Page de reference des composants du framework CSS (assets/css/framework/) :
 * un exemplaire de chaque composant, pour verifier visuellement le rendu
 * apres toute modification de tokens.css ou d'un fichier de components/.
 */
class StyleGuideController extends AbstractController
{
    #[Route('/styleguide', name: 'styleguide_index', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('styleguide/index.html.twig');
    }
}
