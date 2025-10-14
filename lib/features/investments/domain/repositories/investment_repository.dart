import '../entities/investment.dart';
import '../../../../core/utils/result.dart';

/// Interface do repositório de investimentos
abstract class InvestmentRepository {
  /// Obtém lista de investimentos
  Future<Result<List<Investment>>> getInvestments();
  
  /// Obtém investimento por ID
  Future<Result<Investment>> getInvestmentById(String id);
  
  /// Cria novo investimento
  Future<Result<Investment>> createInvestment(Investment investment);
  
  /// Atualiza investimento existente
  Future<Result<Investment>> updateInvestment(Investment investment);
  
  /// Remove investimento
  Future<Result<void>> deleteInvestment(String id);
  
  /// Obtém investimentos por categoria
  Future<Result<List<Investment>>> getInvestmentsByCategory(String category);
  
  /// Obtém investimentos ativos
  Future<Result<List<Investment>>> getActiveInvestments();
}
