/**
 * @description Exécute des recherches SOQL sécurisées sur les Cases liés à un Account.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
public with sharing class CaseSelector {
    // Limite métier/interface : le composant affiche au plus ce nombre de lignes, sans pagination.
    private static final Integer RESULT_LIMIT = 100;

    /**
     * @description Recherche les Cases correspondants et indique si la limite d'affichage de 100 est dépassée.
     * @param accountId ID de l'Account parent.
     * @param subjectSearchTerm Texte à rechercher dans le Subject des Cases.
     * @return Cases correspondants et indicateur de correspondances supplémentaires.
     **/
    public static CaseSearchResult getCasesByAccountIdAndSubject(Id accountId, String subjectSearchTerm) {
        // Construire d'abord la réponse garantit la même structure de DTO pour tous les parcours de sortie.
        CaseSearchResult searchResult = new CaseSearchResult();
        // Initialiser explicitement les deux propriétés pour que les sorties anticipées soient sérialisables par LWC.
        searchResult.cases = new List<Case>();
        searchResult.limitReached = false;

        // Garde-fou : sans ID d'Account ou sans terme non vide, la recherche n'a pas de sens.
        // Renvoyer le DTO initialisé évite un SOQL et prévient une requête trop large par erreur.
        if (accountId == null || String.isBlank(subjectSearchTerm)) {
            return searchResult;
        }

        // Entourer le terme nettoyé de jokers permet à Subject LIKE de rechercher une sous-chaîne.
        // Lier la valeur au lieu de concaténer la saisie utilisateur dans le SOQL.
        String key = '%' + subjectSearchTerm.trim() + '%';
        // Le SOQL doit récupérer une ligne de plus que la limite d'affichage ; elle sert à détecter une troncature.
        Integer queryLimit = RESULT_LIMIT + 1;

        // Récupérer une ligne supplémentaire : 100 résultats seuls ne permettent pas de distinguer 100 de plus de 100.
        // WITH USER_MODE applique les permissions sur les objets et les champs ; with sharing respecte le partage des enregistrements.
        // Id fournit un critère d'ordre stable lorsque plusieurs enregistrements ont le même CreatedDate.
        List<Case> matchingCases = [
            SELECT Id, Subject, Status, Priority
            FROM Case
            WHERE AccountId = :accountId
            AND Subject LIKE :key
            WITH USER_MODE
            ORDER BY CreatedDate DESC, Id DESC
            LIMIT :queryLimit
        ];

        // La 101e ligne prouve la troncature ; seul le booléen correspondant doit parvenir au LWC.
        // Avec LIMIT 101, 101 résultats signifient qu'au moins une correspondance sera masquée.
        searchResult.limitReached = matchingCases.size() > RESULT_LIMIT;
        if (searchResult.limitReached) {
            // Supprimer l'enregistrement supplémentaire à l'index 100 (les index commencent à zéro) pour garder 100 lignes.
            matchingCases.remove(RESULT_LIMIT);
        }

        // Affecter la liste finale après troncature, puis renvoyer le DTO complété.
        searchResult.cases = matchingCases;
        return searchResult;
    }
}