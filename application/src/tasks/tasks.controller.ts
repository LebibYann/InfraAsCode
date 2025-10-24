import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Headers,
  HttpCode,
  HttpStatus,
  ValidationPipe,
} from '@nestjs/common';
import { TasksService } from './tasks.service';
import { CreateTaskDto } from '../dto/create-task.dto';
import { UpdateTaskDto } from '../dto/update-task.dto';
import { DeleteTaskDto } from '../dto/delete-task.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../auth/get-user.decorator';

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body(ValidationPipe) createTaskDto: CreateTaskDto,
    @GetUser('id') userId: string,
    @Headers('correlation_id') correlationId: string,
  ) {
    return await this.tasksService.create(
      createTaskDto,
      userId,
      correlationId || 'no-correlation-id',
    );
  }

  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @GetUser('id') userId: string,
    @Headers('correlation_id') correlationId: string,
  ) {
    return await this.tasksService.findAll(
      userId,
      correlationId || 'no-correlation-id',
    );
  }

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findOne(
    @Param('id') id: string,
    @GetUser('id') userId: string,
    @Headers('correlation_id') correlationId: string,
  ) {
    return await this.tasksService.findOne(
      id,
      userId,
      correlationId || 'no-correlation-id',
    );
  }

  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('id') id: string,
    @Body(ValidationPipe) updateTaskDto: UpdateTaskDto,
    @GetUser('id') userId: string,
    @Headers('correlation_id') correlationId: string,
  ) {
    return await this.tasksService.update(
      id,
      updateTaskDto,
      userId,
      correlationId || 'no-correlation-id',
    );
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async remove(
    @Param('id') id: string,
    @Body(ValidationPipe) deleteTaskDto: DeleteTaskDto,
    @GetUser('id') userId: string,
    @Headers('correlation_id') correlationId: string,
  ) {
    await this.tasksService.remove(
      id,
      deleteTaskDto,
      userId,
      correlationId || 'no-correlation-id',
    );
    return { message: 'Task deleted successfully' };
  }
}
