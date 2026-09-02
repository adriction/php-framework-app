<?php

namespace App\Controller;

use Framework\Controller\AbstractController;
use Framework\Http\Response;
use Framework\Routing\Route;

/**
 * Page d'accueil de depart. Confirme que l'application charge correctement
 * adrien/php-framework depuis vendor/ (routing, DI, Twig).
 *
 * Prochaine etape typique : ajouter tes propres controleurs dans
 * src/App/Controller/, en suivant l'architecture Controller -> Service ->
 * Repository decrite dans la doc du framework (docs/controllers.html).
 */
class HomeController extends AbstractController
{
    #[Route('/', name: 'home', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('home/index.html.twig');
    }
}
