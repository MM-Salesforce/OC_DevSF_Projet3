/**
 * @description Tests unitaires du comportement nominal, de l'ID null et du plafond de résultats d'OpportunitySelector.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
@isTest
private class OpportunitySelectorTest {

    /**
     * Crée des enregistrements de base partagés avant chaque méthode de test.
     * Arrange : utiliser TestDataFactory afin que les tests respectent les mêmes conventions de données que le projet.
     **/
    @testSetup
    static void setup() {
        Account testAccount = TestDataFactory.createTestAccount();
        TestDataFactory.createTestOpportunity(testAccount.Id);
    }

    /**
     * Vérifie qu'une recherche sur l'Account créé par la factory renvoie l'Opportunity attendue.
     * Act : appeler le sélecteur dans la fenêtre d'exécution du test.
     * Assert : vérifier l'enregistrement renvoyé et l'indicateur de dépassement du DTO.
     **/
    @isTest
    static void testGetOpportunitiesByAccountIdSuccess() {
        Account testAccount = getTestAccount();

        Test.startTest();
        OpportunitySearchResult results = OpportunitySelector.getOpportunitiesByAccountId(testAccount.Id);
        Test.stopTest();

        // Le jeu de données de base contient un enregistrement nommé et reste sous le plafond.
        Assert.areEqual(1, results.opportunities.size(), 'Le sélecteur doit retourner exactement une opportunité.');
        Assert.areEqual('Test Opportunity', results.opportunities[0].Name, 'Le résultat doit être celui créé par la Factory.');
        Assert.isFalse(results.limitReached, 'Une recherche sous la limite ne doit pas signaler de dépassement.');
    }

    /**
     * Vérifie le garde-fou du sélecteur lorsque l'appelant ne fournit aucun ID d'Account.
     * La réponse attendue est un DTO vide valide plutôt qu'une requête sans filtre.
     **/
    @isTest
    static void testGetOpportunitiesByAccountIdWithNullId() {
        Test.startTest();
        OpportunitySearchResult results = OpportunitySelector.getOpportunitiesByAccountId(null);
        Test.stopTest();

        Assert.areEqual(0, results.opportunities.size(), 'Un identifiant nul doit produire une liste vide.');
        Assert.isFalse(results.limitReached, 'Un identifiant nul ne peut pas signaler un dépassement.');
    }

    /**
     * Ajoute 100 enregistrements à celui du setup (101 au total) pour tester la troncature.
     * Le sélecteur doit renvoyer les 100 premiers et indiquer la troncature dans le DTO.
     **/
    @isTest
    static void testGetOpportunitiesByAccountIdLimitReached() {
        Account testAccount = getTestAccount();
        insertOpportunities(testAccount.Id, 100);

        Test.startTest();
        OpportunitySearchResult results = OpportunitySelector.getOpportunitiesByAccountId(testAccount.Id);
        Test.stopTest();

        Assert.areEqual(100, results.opportunities.size(), 'Le sélecteur ne doit jamais retourner plus de 100 opportunités.');
        Assert.isTrue(results.limitReached, '101 résultats doivent déclencher le signal de dépassement.');
    }

    /**
     * Ajoute 99 enregistrements à celui du setup (100 au total) pour tester la limite exacte.
     * Cela évite de traiter à tort le plafond exact comme un dépassement.
     **/
    @isTest
    static void testGetOpportunitiesByAccountIdAtExactLimit() {
        Account testAccount = getTestAccount();
        insertOpportunities(testAccount.Id, 99);

        Test.startTest();
        OpportunitySearchResult results = OpportunitySelector.getOpportunitiesByAccountId(testAccount.Id);
        Test.stopTest();

        Assert.areEqual(100, results.opportunities.size(), 'Les 100 résultats doivent être conservés.');
        Assert.isFalse(results.limitReached, 'Exactement 100 résultats ne constituent pas un dépassement.');
    }

    /**
     * Construit les Opportunities supplémentaires des scénarios de limite exacte et de dépassement.
     * L'appelant précise le nombre ; chaque enregistrement est lié au même Account de test.
     */
    private static void insertOpportunities(Id accountId, Integer numberOfOpportunities) {
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();

        // Construire d'abord les enregistrements, puis les insérer en une fois selon la pratique bulk DML.
        for (Integer i = 0; i < numberOfOpportunities; i++) {
            opportunitiesToInsert.add(new Opportunity(
                Name = 'Additional test opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(30),
                AccountId = accountId
            ));
        }

        insert opportunitiesToInsert;
    }

    /**
     * Récupère uniquement l'Account créé par @testSetup afin d'éviter une requête ambiguë.
     * @return L'Account unique créé par la factory de test.
     **/
    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }
}
