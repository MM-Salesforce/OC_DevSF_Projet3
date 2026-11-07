/**
 * @description Expose la récupération des Opportunities d'un Account au LWC accountOpportunitiesViewer.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
public with sharing class AccountOpportunitiesController {
    /**
     * @description Récupère les Opportunities de l'Account affiché par le LWC.
     * @param accountId ID de l'Account fourni par le contexte d'enregistrement du LWC.
     * @return OpportunitySearchResult contenant 100 enregistrements au plus et l'indicateur de dépassement.
     **/
    // AuraEnabled expose la méthode au LWC ; cacheable permet la mise en cache de cette lecture par le wire.
    @AuraEnabled(cacheable=true)
    public static OpportunitySearchResult getOpportunities(Id accountId) {
        // Garder ce contrôleur comme une frontière légère entre interface et données : le sélecteur gère le SOQL et les accès.
        // Le DTO renvoyé devient l'objet { opportunities, limitReached } reçu par JavaScript.
        return OpportunitySelector.getOpportunitiesByAccountId(accountId);
    }
}
