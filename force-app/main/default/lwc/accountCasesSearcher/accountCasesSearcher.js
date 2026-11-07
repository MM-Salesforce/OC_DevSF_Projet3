/**
 * @description Recherche les Cases liés à l'Account courant et prépare leur affichage.
 * @author MM
 * @last modified by MM on 05-11-2026
 **/
import { LightningElement, api } from 'lwc';
import findCasesBySubject from '@salesforce/apex/AccountCasesController.findCasesBySubject';

// lightning-datatable lit chaque cellule à partir du nom API Salesforce du champ correspondant.
// Définir les colonnes hors du composant évite de les recréer à chaque rendu.
const COLUMNS = [
    { label: 'Sujet', fieldName: 'Subject', type: 'text' },
    { label: 'Statut', fieldName: 'Status', type: 'text' },
    { label: 'Priorité', fieldName: 'Priority', type: 'text' },
];

export default class AccountCaseSearchComponent extends LightningElement {
    // Salesforce renseigne cette propriété publique depuis la page d'enregistrement Account qui héberge le composant.
    // Elle est transmise à Apex pour limiter chaque recherche à l'Account affiché.
    @api recordId;

    // Les enregistrements Case de la dernière recherche réussie ; undefined signifie qu'aucune liste n'est affichée.
    cases;

    // Vaut true si le sélecteur a trouvé une 101e correspondance et plafonné la liste renvoyée à 100.
    limitReached = false;

    // Une valeur non vide rend visible l'alerte d'erreur dans le template.
    error = undefined;

    // Reflète la valeur de lightning-input et fournit le texte de recherche à la validation.
    searchTerm = '';

    // Pilote le spinner et désactive les commandes pendant l'attente de la réponse Apex.
    isSearching = false;

    // Rend la définition statique des colonnes accessible au template HTML.
    columns = COLUMNS;

    /**
     * Traite l'événement onchange de lightning-input.
     * event.target.value contient la dernière valeur saisie par l'utilisateur.
     */
    updateSearchTerm(event) {
        this.searchTerm = event.target.value;
    }

    /**
     * Valide la saisie, appelle Apex de manière impérative, puis met à jour l'état de l'interface.
     * L'événement onclick du bouton de recherche est le point d'entrée de ce flux asynchrone.
     */
    async handleSearch() {
        // Retirer une fois les espaces de début et de fin ; utiliser cette valeur normalisée pour la validation et l'appel Apex.
        const subjectSearchTerm = this.searchTerm.trim();

        // Branche 1 : une valeur vide est une erreur de validation côté client ; aucun appel serveur n'est effectué.
        if (!subjectSearchTerm) {
            // Effacer les résultats précédents pour ne pas les confondre avec ceux de cette recherche vide.
            this.cases = undefined;
            this.limitReached = false;
            // Cette chaîne rend l'alerte visible et indique à l'utilisateur comment corriger la saisie.
            this.error = 'Veuillez saisir un sujet à rechercher.';
            return;
        }

        // Branche 2 : une saisie valide lance une nouvelle requête. Effacer l'ancien état avant d'afficher le spinner.
        this.isSearching = true;
        this.cases = undefined;
        this.limitReached = false;
        this.error = undefined;

        try {
            // Un appel Apex impératif renvoie une Promise JavaScript. await suspend cette méthode async
            // jusqu'à la réponse du serveur, puis affecte le DTO désérialisé à results.
            const results = await findCasesBySubject({
                accountId: this.recordId,
                subjectSearchTerm
            });

            // Branche 3 : vérifier la structure de la réponse avant d'accéder à ses propriétés.
            // Apex doit renvoyer { cases: Case[], limitReached: Boolean }.
            if (!results || !Array.isArray(results.cases) || typeof results.limitReached !== 'boolean') {
                // Il s'agit d'une réponse qui ne respecte pas le contrat attendu, et non d'une Promise Apex rejetée.
                this.error = 'La recherche a renvoyé une réponse inattendue.';
                return;
            }

            // Branche de succès : affecter les données et le signal de dépassement à l'état réactif du LWC.
            // Ces affectations font réévaluer les getters du template et ses blocs conditionnels.
            this.cases = results.cases;
            this.limitReached = results.limitReached;
        } catch {
            // Branche d'erreur : une Promise rejetée (exception Apex, droits insuffisants ou erreur réseau)
            // arrive ici. Afficher un message compréhensible plutôt que des détails techniques.
            this.cases = undefined;
            this.limitReached = false;
            this.error = 'Une erreur est survenue lors de la recherche des cas.';
        } finally {
            // finally s'exécute après un succès comme après un échec ; le spinner s'arrête et les commandes sont réactivées.
            this.isSearching = false;
        }
    }

    /**
     * Getter du template : active les vues des résultats lorsqu'au moins un Case est présent.
     * Array.isArray évite aussi de lire length sur undefined ou sur une valeur inattendue.
     */
    get hasCases() {
        return Array.isArray(this.cases) && this.cases.length > 0;
    }

    /**
     * Getter du template : vaut true après une recherche réussie qui renvoie un tableau vide.
     * Il reste false avant la recherche, lorsque cases vaut undefined.
     */
    get showNoResults() {
        return Array.isArray(this.cases) && this.cases.length === 0;
    }

    /**
     * Getter du template pour le texte visible dans l'alerte.
     * Un objet vide est truthy et peut activer lwc:if={error}, mais son affichage direct
     * produirait « [object Object] » ; renvoyer un texte de secours lisible pour toute valeur non textuelle.
     */
    get errorMessage() {
        return typeof this.error === 'string'
            ? this.error
            : 'Une erreur est survenue lors de la recherche des cas.';
    }
}
