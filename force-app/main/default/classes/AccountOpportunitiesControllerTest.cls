/**
 * @description Tests unitaires de la frontière AccountOpportunitiesController appelée par le LWC.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
@isTest
private class AccountOpportunitiesControllerTest {

    /**
     * Crée un Account et son Opportunity associée comme données de base communes aux tests.
     * Arrange : TestDataFactory centralise les champs requis et insère les deux enregistrements.
     **/
    @testSetup
    static void setupData() {
        Account testAccount = TestDataFactory.createTestAccount();
        TestDataFactory.createTestOpportunity(testAccount.Id);
    }

    /**
     * Vérifie le point d'entrée Apex complet appelé par le LWC avec un Account valide.
     * Le contrôleur délègue au sélecteur et renvoie son DTO sans le modifier.
     **/
    @isTest
    static void testGetOpportunitiesSuccess() {
        Account accountRecord = getTestAccount();

        Test.startTest();
        OpportunitySearchResult results = AccountOpportunitiesController.getOpportunities(accountRecord.Id);
        Test.stopTest();

        Assert.areEqual(1, results.opportunities.size(), 'Le contrôleur doit transmettre une opportunité.');
        Assert.areEqual('Test Opportunity', results.opportunities[0].Name, 'Le DTO doit contenir l’opportunité de test.');
        Assert.isFalse(results.limitReached, 'Le résultat nominal ne doit pas signaler de dépassement.');
    }

    /**
     * Vérifie que le contrôleur conserve la réponse vide sécurisée du sélecteur lorsque l'ID est null.
     * Ce test valide aussi l'intégration contrôleur-sélecteur sur le parcours de sortie anticipée.
     **/
    @isTest
    static void testGetOpportunitiesWithNullId() {
        Test.startTest();
        OpportunitySearchResult results = AccountOpportunitiesController.getOpportunities(null);
        Test.stopTest();

        Assert.areEqual(0, results.opportunities.size(), 'Un identifiant nul doit retourner une liste vide.');
        Assert.isFalse(results.limitReached, 'Un identifiant nul ne doit pas signaler de dépassement.');
    }

    /**
     * Recherche l'Account unique créé par @testSetup plutôt qu'un enregistrement arbitraire.
     * @return L'Account de test créé par la factory.
     **/
    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }
}
