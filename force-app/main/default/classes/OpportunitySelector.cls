/**
 * @description Exécute la requête SOQL sécurisée sur les Opportunities liées à un Account.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
public with sharing class OpportunitySelector {
    // Limite métier/interface : le composant affiche 100 enregistrements au maximum, sans pagination.
    private static final Integer RESULT_LIMIT = 100;

    /**
     * @description Recherche les Opportunities d'un Account et indique si plus de 100 correspondent.
     * @param accountId ID de l'Account parent.
     * @return Opportunities correspondantes et indicateur de résultats supplémentaires.
     **/
    public static OpportunitySearchResult getOpportunitiesByAccountId(Id accountId) {
        // Initialiser les deux propriétés du DTO pour conserver la même structure de réponse vers le LWC.
        OpportunitySearchResult searchResult = new OpportunitySearchResult();
        searchResult.opportunities = new List<Opportunity>();
        searchResult.limitReached = false;

        // Garde-fou : sans ID d'Account, ne pas lancer de requête sans filtre de compte.
        if (accountId == null) {
            return searchResult;
        }

        // Récupérer une ligne de plus que la limite permet de distinguer 100 correspondances exactes d'un dépassement.
        // USER_MODE applique les permissions sur les objets/champs ; with sharing applique le partage des enregistrements.
        // Id stabilise l'ordre lorsque plusieurs Opportunities ont le même CloseDate.
        List<Opportunity> matchingOpportunities = [
            SELECT Id, Name, Amount, CloseDate, StageName
            FROM Opportunity
            WHERE AccountId = :accountId
            WITH USER_MODE
            ORDER BY CloseDate DESC, Id DESC
            LIMIT 101
        ];

        // La présence d'une 101e ligne prouve qu'au moins une correspondance doit être omise de la liste affichée.
        searchResult.limitReached = matchingOpportunities.size() > RESULT_LIMIT;
        if (searchResult.limitReached) {
            // Les listes Apex commencent à l'index zéro : l'index 100 est la 101e ligne, utilisée uniquement pour la détection.
            matchingOpportunities.remove(RESULT_LIMIT);
        }

        // Placer le résultat plafonné dans le DTO ; le contrôleur le transmet au wire du LWC.
        searchResult.opportunities = matchingOpportunities;
        return searchResult;
    }
}
