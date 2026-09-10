/*
 * JS des composants du framework CSS (assets/css/framework/components/).
 * Vanilla JS, sans dependance, pilote entierement par des attributs
 * data-* sur le HTML — rien a instancier cote app.
 *
 * API :
 *   Collapse (menu mobile navbar, panneau repliable)
 *     <button data-toggle="collapse" data-target="#id">
 *     <div id="id"> ...              -> classe .show basculee sur la cible
 *
 *   Onglets (.nav-tabs / .tab-content > .tab-pane)
 *     <div class="nav-tabs">
 *       <a class="nav-link active" data-toggle="tab" data-target="#pane1">
 *       <a class="nav-link" data-toggle="tab" data-target="#pane2">
 *     </div>
 *     <div class="tab-content">
 *       <div class="tab-pane active" id="pane1">...
 *       <div class="tab-pane" id="pane2">...
 *
 *   Modal
 *     <button data-toggle="modal" data-target="#myModal">Ouvrir</button>
 *     <div class="modal" id="myModal">
 *       ...<button class="btn-close" data-dismiss="modal"></button>
 *     </div>
 *     Le backdrop (.modal-backdrop) est cree et gere automatiquement, pas
 *     besoin de le declarer dans le HTML. Fermeture aussi via Echap ou
 *     clic sur le backdrop.
 *
 *   Alerte fermable (.alert-dismissible)
 *     <button class="btn-close" data-dismiss="alert"></button>
 *     -> retire du DOM le .alert parent le plus proche.
 */
(function () {
    'use strict';

    /* Collapse ----------------------------------------------------------- */
    document.addEventListener('click', function (event) {
        var trigger = event.target.closest('[data-toggle="collapse"]');
        if (!trigger) {
            return;
        }
        var target = document.querySelector(trigger.getAttribute('data-target'));
        if (target) {
            target.classList.toggle('show');
        }
    });

    /* Onglets -------------------------------------------------------------- */
    document.addEventListener('click', function (event) {
        var tabLink = event.target.closest('[data-toggle="tab"]');
        if (!tabLink) {
            return;
        }
        event.preventDefault();

        var tabGroup = tabLink.closest('.nav-tabs');
        if (tabGroup) {
            tabGroup.querySelectorAll('.nav-link.active').forEach(function (link) {
                link.classList.remove('active');
            });
        }
        tabLink.classList.add('active');

        var pane = document.querySelector(tabLink.getAttribute('data-target'));
        if (pane && pane.parentElement) {
            pane.parentElement.querySelectorAll('.tab-pane.active').forEach(function (activePane) {
                activePane.classList.remove('active');
            });
            pane.classList.add('active');
        }
    });

    /* Modal -----------------------------------------------------------------
     * Un seul backdrop partage, cree a la demande et reutilise pour
     * n'importe quel modal — evite d'avoir a en declarer un par modal.
     * ------------------------------------------------------------------- */
    var backdrop = null;

    function getBackdrop() {
        if (!backdrop) {
            backdrop = document.createElement('div');
            backdrop.className = 'modal-backdrop';
            document.body.appendChild(backdrop);
            backdrop.addEventListener('click', closeOpenModal);
        }
        return backdrop;
    }

    function openModal(modal) {
        getBackdrop().classList.add('show');
        modal.classList.add('show');
        document.body.style.overflow = 'hidden';
    }

    function closeOpenModal() {
        var openModalEl = document.querySelector('.modal.show');
        if (!openModalEl) {
            return;
        }
        openModalEl.classList.remove('show');
        if (backdrop) {
            backdrop.classList.remove('show');
        }
        document.body.style.overflow = '';
    }

    document.addEventListener('click', function (event) {
        var opener = event.target.closest('[data-toggle="modal"]');
        if (opener) {
            var modal = document.querySelector(opener.getAttribute('data-target'));
            if (modal) {
                openModal(modal);
            }
            return;
        }
        if (event.target.closest('[data-dismiss="modal"]')) {
            closeOpenModal();
        }
    });

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') {
            closeOpenModal();
        }
    });

    /* Alertes fermables --------------------------------------------------- */
    document.addEventListener('click', function (event) {
        var closer = event.target.closest('[data-dismiss="alert"]');
        if (!closer) {
            return;
        }
        var alertEl = closer.closest('.alert');
        if (alertEl) {
            alertEl.remove();
        }
    });

})();
