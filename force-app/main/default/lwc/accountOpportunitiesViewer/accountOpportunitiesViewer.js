/**
 * @description Affiche les Opportunities liées à l'Account de la page courante.
 * @author MM
 * @last modified by MM on 05-11-2026
 **/
import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOpportunities from '@salesforce/apex/AccountOpportunitiesController.getOpportunities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountOpportunitiesViewer extends LightningElement {
    // Salesforce fournit l'ID de l'Account courant lorsque ce composant est placé sur une record page.
    // Cette valeur devient le paramètre accountId de la méthode Apex connectée au wire ci-dessous.
    @api recordId;

    // Opportunities renvoyées par Apex ; undefined signifie qu'aucune réponse réussie n'est affichée.
    opportunities;

    // Vaut true si Apex a trouvé une 101e correspondance et n'a donc renvoyé que les 100 premières Opportunities.
    limitReached = false;

    // Stocke l'objet d'erreur du wire ; une valeur truthy rend l'alerte visible dans le template.
    error = undefined;

    // Conserver le résultat complet du wire, pas seulement ses données : refreshApex a besoin de cette valeur.
    wiredOpportunitiesResult;

    // Pilote le spinner de rafraîchissement et empêche les demandes simultanées.
    isRefreshing = false;

    // Définitions des champs utilisés par la datatable sur grand écran.
    columns = [
        { label: 'Nom Opportunité', fieldName: 'Name', type: 'text' },
        { label: 'Montant', fieldName: 'Amount', type: 'currency' },
        { label: 'Date de Clôture', fieldName: 'CloseDate', type: 'date' },
        { label: 'Phase', fieldName: 'StageName', type: 'text' }
    ];

    /**
     * Connecte Apex au contexte de l'Account de la record page.
     * Salesforce appelle cette méthode lorsque recordId devient disponible et lors d'un rafraîchissement du wire.
     */
    @wire(getOpportunities, { accountId: '$recordId' })
    wiredOpportunities(result) {
        // Conserver toute la réponse du wire pour que handleRafraichir puisse demander sa réexécution à refreshApex.
        this.wiredOpportunitiesResult = result;
        const { data, error } = result;

        // Branche de succès : Apex a renvoyé un DTO OpportunitySearchResult.
        if (data) {
            // Copier les deux propriétés du DTO utilisées par le template : les lignes et l'indicateur de dépassement.
            this.opportunities = data.opportunities;
            this.limitReached = data.limitReached;

            // Effacer une éventuelle erreur provenant d'une réponse précédente du wire.
            this.error = undefined;
        } else if (error) {
            // Branche d'erreur : conserver l'objet afin d'activer l'alerte accessible du template.
            this.error = error;
            this.opportunities = undefined;
            this.limitReached = false;
        }
        // Si data et error sont absents, le wire charge encore ; ne pas appliquer un état final à l'interface.
    }

    /**
     * Traite le clic sur le bouton Refresh et demande à Salesforce d'actualiser le résultat Apex du wire.
     */
    async handleRafraichir() {
        // Activer l'indicateur avant await pour afficher le spinner pendant le rafraîchissement asynchrone.
        this.isRefreshing = true;

        try {
            // refreshApex reçoit le résultat wire conservé et relance sa source Apex.
            // Le callback du wire met à jour opportunities ou error à l'arrivée de la nouvelle réponse.
            await refreshApex(this.wiredOpportunitiesResult);
        } catch (error) {
            // Le rejet de la Promise de rafraîchissement ne signifie pas nécessairement que les données affichées ont été effacées.
            // Journaliser le détail pour le diagnostic et afficher à l'utilisateur un toast concis.
            console.error('Erreur lors du rafraîchissement :', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Rafraîchissement impossible',
                    message: 'Les données affichées peuvent être obsolètes. Réessayez.',
                    variant: 'error'
                })
            );
        } finally {
            // finally s'exécute après succès comme après échec et garantit l'arrêt du spinner.
            this.isRefreshing = false;
        }
    }

    /**
     * Détermine si le bouton Refresh doit être désactivé.
     * Il l'est pendant un rafraîchissement et avant que le wire ait renvoyé des données ou une erreur.
     */
    get isRefreshDisabled() {
        return this.isRefreshing || (!this.opportunities && !this.error);
    }

    /**
     * Condition du template : indique s'il faut afficher le tableau ou les cartes lorsque des lignes existent.
     */
    get hasOpportunities() {
        return Array.isArray(this.opportunities) && this.opportunities.length > 0;
    }

    /**
     * Condition du template : affiche l'état vide après une réponse réussie sans ligne.
     * Elle reste false avant l'arrivée des données, car opportunities vaut alors undefined.
     */
    get isOpportunitiesEmpty() {
        return Array.isArray(this.opportunities) && this.opportunities.length === 0;
    }
}
